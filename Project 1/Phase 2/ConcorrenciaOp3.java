import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Classe para correr testes da Operacoes 3
 * Ver readme com instrucoes para correr
 * @author Grupo 10 TBD 2018/2019
 *
 */
public class ConcorrenciaOp3 implements Runnable {


	// Constantes -------------------------------------------------------------


	private static final String LIGACAO = "jdbc:postgresql://localhost/ProjetoTBD";


	private static final String UTILIZADOR = "postgres";
	private static final String SENHA = "bd-diogo";

	private static final String OPERACAO = "SELECT * FROM operacao3()";

	// --------------------------------------------------------------------------


	// Variáveis --------------------------------------------------------------


	private Connection objLigacao = null;


	private CallableStatement objComando = null;

	private int nThread;


	public ConcorrenciaOp3(int nThread) {
		this.nThread = nThread;
	}

	@Override
	public void run() {
		try {
			objLigacao = DriverManager.getConnection(LIGACAO, UTILIZADOR, SENHA);
			objLigacao.setAutoCommit(false);

			try {

				objComando = objLigacao.prepareCall(OPERACAO);

				objComando.execute();
				objComando.close();


				objLigacao.commit();

				System.out.println("A operacao 3 foi executada!");

			} catch (SQLException objExcepcao) {


				objComando.close();
				objLigacao.rollback();
				System.out.println("A thread " + nThread + " terminou devido a problema na transação.");
			}

		} catch (SQLException e) {
			e.printStackTrace();
		}
	}


	public static void main(String[] args) {

		try {
			Class.forName("org.postgresql.Driver");
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		}

		ConcorrenciaOp3 primeiraOperacao = new ConcorrenciaOp3(1);
		ConcorrenciaOp3 segundaOperacao = new ConcorrenciaOp3(2);

		Thread objThread1 = new Thread(primeiraOperacao);
		Thread objThread2 = new Thread(segundaOperacao);

		objThread1.start();
		objThread2.start();

		System.out.println("Aguardando fim de actividade de ambas as threads");

		try {
			objThread1.join();
			objThread2.join();
		} catch (InterruptedException objExcepcao) { }

		System.out.println("Fim do programa");

	}
}