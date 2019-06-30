import java.sql.Array;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Classe para correr testes das Operacoes 1 e 2
 * Ver readme com instrucoes para correr
 * @author Grupo 10 TBD 2018/2019
 *
 */
public class Operacoes1e2 implements Runnable {

	// Constantes -------------------------------------------------------------

	private static final String LIGACAO = "jdbc:postgresql://localhost/ProjetoTBD";


	private static final String UTILIZADOR = "postgres";
	private static final String SENHA = "bd-diogo";


	private static final int CLIENTE1 = 15483;


	private static final int CLIENTE2 = 9315;

	private static final String COMPRA =
			"SELECT * FROM compra(?, ?, ?);";

	// --------------------------------------------------------------------------


	// Variáveis --------------------------------------------------------------


	private Connection objLigacao = null;
	private CallableStatement objComando = null;
	private int intRef;
	private Array prods = null;
	private Array qtys = null;

	public Operacoes1e2(int cliente, Object[] prodsPassed, Object[] qtysPassed) {

		this.intRef = cliente;
		try {
			objLigacao = DriverManager.getConnection(LIGACAO, UTILIZADOR, SENHA);
			this.prods = objLigacao.createArrayOf("INTEGER", prodsPassed);
			this.qtys = objLigacao.createArrayOf("INTEGER", qtysPassed);
		} catch (SQLException e) {
			System.out.println("Deu Badagaio");
		}
	}

	@Override
	/**
	 * Metodo que cada thread corre
	 */
	public void run() {
		try {

			objLigacao.setAutoCommit(false);

			try {

				objComando = objLigacao.prepareCall(COMPRA);

				// O parametro será o cliente.
				objComando.setInt(1, intRef);
				objComando.setArray(2, prods);
				objComando.setArray(3, qtys);

				objComando.execute();
				objComando.close();

				objLigacao.commit();

				System.out.println("Compra efetuada pelo cliente: " + intRef);

			} catch (SQLException objExcepcao) {

				objComando.close();
				objLigacao.rollback();
				System.out.println("A operacao de compra falhou!");
				System.out.println("Error Message: " + objExcepcao.getMessage());
			}
		} catch (SQLException objExcepcao) {
			System.out.println("Error Message: " + objExcepcao.getMessage());
		}

		// Libertação de recursos.
		try {
			prods.free();
			qtys.free();
			objLigacao.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}

	}

	public static void main(String[] args) {

		// Carregamento do driver PostgreSQL.
		try {
			Class.forName("org.postgresql.Driver");
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		}

		Operacoes1e2 objInstancia1 = new Operacoes1e2(CLIENTE1,new Object[]{8},new Object[]{10}); 
		Operacoes1e2 objInstancia2 = new Operacoes1e2(CLIENTE2,new Object[]{12},new Object[]{5}); 

		Thread objThread1 = new Thread(objInstancia1);
		Thread objThread2 = new Thread(objInstancia2);

		objThread1.start();
		objThread2.start();

		// Aguarda fim de actividade de ambas as threads.
		System.out.println("Aguardando o fim de actividade de ambas as threads");

		try {
			objThread1.join();
			objThread2.join();
		} catch (InterruptedException objExcepcao) { }

		System.out.println("Fim do programa");
	}
}