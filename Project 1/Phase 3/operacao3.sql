
DROP INDEX IF EXISTS idx1;
    CREATE INDEX idx1 ON inventory USING btree (((quan_in_stock::decimal)/(quan_in_stock + sales)::decimal) ASC);

CREATE OR REPLACE FUNCTION operacao3 ()
RETURNS VOID AS
$$
DECLARE

lista_prods INTEGER[];

size_lista_prods INTEGER := 0;
div_result INTEGER := 0; 
quan_stock INTEGER := 0;
n_sales INTEGER := 0;


BEGIN
    LOCK TABLE inventory IN SHARE ROW EXCLUSIVE MODE;

    lista_prods := ARRAY(SELECT i.prod_id
                        FROM inventory i
                        WHERE ((i.quan_in_stock::decimal)/(i.quan_in_stock + i.sales)::decimal) < 0.2
                        ORDER BY i.sales DESC, i.prod_id ASC) AS lista_prods;
    
    size_lista_prods = array_length(lista_prods,1);

    div_result = FLOOR(size_lista_prods / 3);
    
    FOR i IN 1.. 2*div_result LOOP -- percorre os 2 grupos
        
         SELECT INV.quan_in_stock INTO quan_stock
           FROM inventory INV
          WHERE INV.prod_id = lista_prods[i];

        SELECT INV.sales INTO n_sales
          FROM inventory INV
         WHERE INV.prod_id = lista_prods[i];

        IF(i <= div_result) THEN  -- prods mais vendidos
            INSERT INTO reorder(prod_id,date_low,quan_low,date_reordered,quan_reordered,date_expected)
                VALUES(lista_prods[i],CURRENT_DATE - 1,quan_stock,CURRENT_DATE,(quan_stock + n_sales)*1.5,CURRENT_DATE + 7);

            UPDATE inventory inv
			SET quan_in_stock = quan_in_stock + (quan_stock + n_sales)*1.5
			WHERE inv.prod_id = lista_prods[i];
            RAISE NOTICE 'Produto -> %  + 50;', lista_prods[i]; 

        ELSE -- produtos do meio
             INSERT INTO reorder(prod_id,date_low,quan_low,date_reordered,quan_reordered,date_expected)
                 VALUES(lista_prods[i],CURRENT_DATE - 1,quan_stock,CURRENT_DATE,(quan_stock + n_sales)*1.2,CURRENT_DATE + 7);
			
			UPDATE inventory inv
			SET quan_in_stock = quan_in_stock + (quan_stock + n_sales)*1.2
			WHERE inv.prod_id = lista_prods[i];
            RAISE NOTICE 'Produto -> %  + 20;', lista_prods[i]; 
        END IF;

    END LOOP;
END;

$$ LANGUAGE plpgsql;