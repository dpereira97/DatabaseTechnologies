﻿CREATE OR REPLACE FUNCTION compra(
   num_cliente customers.customerid%TYPE, 
   prods integer[], 
   quantidades integer[]
)

RETURNS VOID AS
$$
DECLARE
cust INTEGER := 0;
n_prods INTEGER := 0;
price_acc NUMERIC(12,2) := 0.0; -- acumular precos para totalamount
preco NUMERIC(12,2) := 0.0;
id_order INTEGER := 0;
idprod INTEGER := 0;
tax_new NUMERIC(12,2) := 0;
total NUMERIC (12,2) := 0;
stock INTEGER := 0;

--------- var primeira compra --------
n_vezes INTEGER := 0; -- numeros de vezes que o user fez compras

--lista de produtos com desconto - para a primeira compra
lista_prods_desc INTEGER[];
n_lista_prods_desc INTEGER := 0;
produto_com_desconto BOOLEAN := FALSE;
--------------------------------------

---------- var melhor cliente --------
--lista dos melhores clientes
lista_n_melhores_clientes INTEGER ARRAY := ARRAY(SELECT DISTINCT TC.top_ids
FROM (SELECT O.customerid AS top_ids, SUM(O.totalamount)
	  FROM orders O, customers C
	  WHERE (O.customerid = C.customerid)
	  AND C.age > 50
	  GROUP BY O.customerid
	  ORDER BY SUM(O.totalamount) DESC, O.customerid ASC
	  LIMIT 1000) AS TC , cust_hist CU
WHERE (TC.top_ids = CU.customerid)
AND CU.prod_id IN (SELECT OL.prod_id
					FROM orderlines OL
					WHERE OL.orderdate >= date_trunc('month', current_date - interval '1' month)
					AND OL.orderdate < date_trunc('month', current_date)
					GROUP BY OL.prod_id
					ORDER BY SUM(OL.quantity) DESC, OL.prod_id ASC
					LIMIT 50));

n_melhores_clientes INTEGER := 0;
eh_melhor_cliente BOOLEAN := FALSE;
id_cat_menos_vendida INTEGER := 0;
cat_prod_compra INTEGER := 0;

--------------------------------------

BEGIN
    -- Guardar o id do cliente na var cust
    SELECT C.customerid INTO cust
    FROM customers C
    WHERE C.customerid = num_cliente;
  
    -- se o cliente nao existe entao nao pode comprar
    IF (cust ISNULL) THEN
        RAISE EXCEPTION 'O cliente com o id: % nao existe', num_cliente;
        RETURN;
    END IF;

    n_prods = array_length(prods,1); -- extrarir numero de prods
    -- iterar a lista de prods que o cliente comprou
    FOR i IN 1.. n_prods LOOP
        SELECT P.prod_id INTO idprod
        FROM products P
        WHERE P.prod_id = prods[i];
        -- se um prod nao existe
        IF (idprod ISNULL) THEN
            RAISE EXCEPTION 'O produto com o id: % nao existe', prods[i];
            RETURN;
        END IF;
    END LOOP;

    ---------- criar uma order (incompleta) ----------
    -- id da order (gerada sequencialmente)
    id_order := nextval('orders_orderid_seq');
    --criar uma order sem todos os valores, vao ser calculados depois de criar as orderlines
    INSERT INTO orders(orderid, orderdate,customerid,netamount,tax,totalamount)
    VALUES (id_order,current_date,cust,0.0,0.0,0.0);
---------- FIM criar uma order (incompleta) ----------

---------- ver se eh a primeira compra do cliente ----------
    LOCK TABLE cust_hist IN SHARE ROW EXCLUSIVE MODE;
    SELECT COUNT(CH.customerid) INTO n_vezes
    FROM cust_hist CH
    WHERE CH.customerid = cust;
---------- FIM ver se eh a primeira compra do cliente ----------

---------- verifica se eh melhor cliente -> se for muda ao booleano para true ----------
    n_melhores_clientes = array_length(lista_n_melhores_clientes,1);
    IF (n_melhores_clientes > 0) THEN
        FOR i IN 1.. n_melhores_clientes LOOP
            IF (lista_n_melhores_clientes[i] = cust) THEN -- eh um melhor cliente
                RAISE NOTICE 'O cliente com o id % pertence aos melhores clientes', cust;
                eh_melhor_cliente = TRUE;       
                EXIT; -- sair do ciclo
            END IF;          
        END LOOP;
    END IF;
---------- FIM verifica se eh melhor cliente ----------

--------------------------------------------------------------------------------
--------- IF's -> verificações se o cliente tem descontou ou nao ---------------
--------- Verificacao se eh a primeira compra || se eh melhor cliene -----------
--------------------------------------------------------------------------------

    -- Se for a primeira compra
    IF (n_vezes = 0) THEN
        RAISE NOTICE '-> % ', n_vezes;
    --------- inicio da primeira compra ----------
        RAISE NOTICE 'Primeira compra do cliente';

        --vai buscar produtos com desconto
        SELECT array(SELECT p.prod_id
            FROM inventory i, products p
            WHERE (i.prod_id = p.prod_id)
            AND p.price < 15
            ORDER BY i.quan_in_stock DESC, p.prod_id
            LIMIT 50) into lista_prods_desc;

        n_lista_prods_desc = array_length(lista_prods_desc,1); --numero de prods com desconto

        FOR i IN 1.. n_prods LOOP
            -- ir buscar o preco do prod
            SELECT p.price into preco
            FROM products p
            WHERE p.prod_id = prods[i];

            SELECT iv.quan_in_stock INTO stock
            FROM inventory iv
            WHERE iv.prod_id = prods[i];

            IF (stock < quantidades[i]) THEN
                RAISE EXCEPTION 'So ha % de stock do produto %', stock, prods[i];
            END IF;
            
            FOR n IN 1.. n_lista_prods_desc LOOP 
                IF (prods[i] = lista_prods_desc[n]) THEN
                    RAISE NOTICE 'produto % com desconto', prods[i];
                    --atualizar preco total aplicando o desconto de 15%
                    price_acc := (price_acc + (preco * 0.85)) * quantidades[i];
                    produto_com_desconto := TRUE;
                END IF;
            END LOOP;

            IF (produto_com_desconto = FALSE) THEN
                RAISE NOTICE 'produto % sem desconto', prods[i];
                --atualizar preco total sem o desconto de 15%
                price_acc := (price_acc + preco) * quantidades[i];
            END IF;
            
            produto_com_desconto := FALSE; --reset ao valor

            -- Inserir cada prod na orderlines
            INSERT INTO orderlines(orderlineid, orderid,prod_id,quantity,orderdate)
            VALUES (i,id_order,prods[i],quantidades[i],current_date);  
                                      
            -- mudar stock e sales no inventory
            UPDATE inventory inv
            SET quan_in_stock = quan_in_stock - quantidades[i], sales = sales + quantidades[i]
            WHERE inv.prod_id = prods[i];

            -- inserir o cust_hist
            INSERT INTO cust_hist(customerid, orderid, prod_id)
            VALUES (cust,id_order,prods[i]);
          
        END LOOP;
    ---------- fim da primeira compra ----------
    
    ---------- verifica melhor cliente ----------
    ELSIF (eh_melhor_cliente = TRUE) THEN

        RAISE NOTICE 'Melhor cliente';

        -- vai buscar a categoria menos vendida
        LOCK TABLE inventory IN EXCLUSIVE MODE;
        SELECT MV.min_cat INTO id_cat_menos_vendida
        FROM(SELECT P.category AS min_cat,SUM(I.sales)
            FROM products P, inventory I
            WHERE (P.prod_id = I.prod_id)
            GROUP BY P.category
            ORDER BY SUM(I.sales) ASC
            LIMIT 1) AS MV;

        FOR i IN 1.. n_prods LOOP
            -- ir buscar o preco do prod
            SELECT p.price into preco
            FROM products p
            WHERE p.prod_id = prods[i];

            -- ir buscar cat do prod
            SELECT p.category into cat_prod_compra
            FROM products p
            WHERE p.prod_id = prods[i];
            
            SELECT iv.quan_in_stock INTO stock
            FROM inventory iv
            WHERE iv.prod_id = prods[i];
            
            IF (stock < quantidades[i]) THEN
                RAISE EXCEPTION 'So ha % de stock do produto %', stock, prods[i];
            END IF;            
            IF (cat_prod_compra = id_cat_menos_vendida) THEN -- prod esta em desconto
                RAISE NOTICE 'produto % com desconto de %', prods[i], preco * 0.80;
                price_acc := (price_acc + (preco * 0.80)) * quantidades[i]; --atualizar preco com 20% de desconto
            ELSE
                RAISE NOTICE 'produto % sem desconto', prods[i];
                price_acc := (price_acc + preco) * quantidades[i]; --atualizar preco com sem desconto
                RAISE NOTICE 'preco prod s/ desc  % ', preco;
            END IF;
            RAISE NOTICE 'Preco acumulado = % ', price_acc;

           -- Inserir cada prod na orderlines
           INSERT INTO orderlines(orderlineid, orderid,prod_id,quantity,orderdate)
           VALUES (i,id_order,prods[i],quantidades[i],current_date);  
                                      
           -- mudar stock e sales no inventory
           UPDATE inventory inv
           SET quan_in_stock = quan_in_stock - quantidades[i], sales = sales + quantidades[i]
           WHERE inv.prod_id = prods[i];

           -- inserir o cust_hist
           INSERT INTO cust_hist(customerid, orderid, prod_id)
           VALUES (cust,id_order,prods[i]);
          
        END LOOP;
     ---------- fim melhor cliente ----------
   ELSE

   RAISE NOTICE 'O cliente ja tinha efetuado compras';
   ----------       
   --percorrer todos os produtos
    FOR i IN 1.. n_prods LOOP
  
        -- ir buscar o preco do prod
        SELECT p.price into preco
        FROM products p
        WHERE p.prod_id = prods[i];

        SELECT iv.quan_in_stock INTO stock
            FROM inventory iv
            WHERE iv.prod_id = prods[i];
            
        IF (stock < quantidades[i]) THEN
            RAISE EXCEPTION 'So ha % de stock do produto %', stock, prods[i];
        END IF;
      
        --atualizar preco total
        price_acc := (price_acc + preco) * quantidades[i];
      
        -- Inserir cada prod na orderlines
        INSERT INTO orderlines(orderlineid, orderid,prod_id,quantity,orderdate)
        VALUES (i,id_order,prods[i],quantidades[i],current_date);  
                                  
        -- mudar stock e sales no inventory
        UPDATE inventory inv
        SET quan_in_stock = quan_in_stock - quantidades[i], sales = sales + quantidades[i]
        WHERE inv.prod_id = prods[i];

        -- inserir o cust_hist
        INSERT INTO cust_hist(customerid, orderid, prod_id)
        VALUES (cust,id_order,prods[i]);

    END LOOP;
           
    END IF;         

        --atualizar order
        tax_new := price_acc * 0.1212;
        total := tax_new + price_acc;
        RAISE NOTICE '-> price_acc %', price_acc;
        UPDATE orders
        SET netamount = price_acc, tax = tax_new, totalamount = total
        WHERE orderid = id_order;               
END;
$$
LANGUAGE plpgsql;
