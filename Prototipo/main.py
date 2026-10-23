"""
SCC0640 - Projeto de Bases de Dados
main.py - Protótipo do Sistema de Gestão de Eventos e Espaços
"""

import json
from pathlib import Path

import psycopg
from ollama import Client


# ============================================================
# Configuração (padrão obrigatório do PDF)
# ============================================================
BASE_DIR = Path(__file__).resolve().parent

with open(BASE_DIR / "config.json", encoding="utf-8") as f:
    config = json.load(f)


# ============================================================
# Extração do DDL do Projeto.txt (padrão obrigatório do PDF)
# ============================================================
projeto_path = BASE_DIR.parent / "Projeto.txt"
if not projeto_path.exists():
    print("Erro: Projeto.txt não encontrado.")
    raise SystemExit(1)
projeto = projeto_path.read_text(encoding="utf-8")

try:
    ddl = projeto.split("3. DDL COMPLETO", 1)[1]
    ddl = ddl.split("4. CONSULTAS", 1)[0]
    ddl = ddl.strip()
except IndexError:
    print("Erro: marcadores '3. DDL COMPLETO' / '4. CONSULTAS' não encontrados.")
    raise SystemExit(1)


# ============================================================
# Extração das 5 consultas
# ============================================================
def extrair_consultas(texto):
    try:
        secao4 = texto.split("4. CONSULTAS", 1)[1]
        secao4 = secao4.split("FIM DO ARQUIVO", 1)[0]
    except IndexError:
        return []

    consultas = []
    blocos = secao4.split("CONSULTA ")
    for i in range(1, 6):
        try:
            bloco = blocos[i]
            objetivo = bloco.split("OBJETIVO:", 1)[1].split("\n", 1)[0].strip()
            sql_parte = bloco.split("SQL:", 1)[1]
            sql = sql_parte.split("=========================================", 1)[0].strip()
            consultas.append({"numero": i, "objetivo": objetivo, "sql": sql})
        except (IndexError, ValueError):
            consultas.append({"numero": i, "objetivo": "(não extraída)", "sql": None})
    return consultas


consultas = extrair_consultas(projeto)
if len(consultas) != 5 or any(c["sql"] is None for c in consultas):
    print("Aviso: nem todas as 5 consultas foram extraídas corretamente.")


# ============================================================
# Helpers
# ============================================================
def executar_sql(conn, sql):
    try:
        with conn.cursor() as cur:
            cur.execute(sql)
            if cur.description is None:
                return None, "A consulta não retornou resultados (não é SELECT?)."
            colunas = [d[0] for d in cur.description]
            linhas = cur.fetchall()
            return (colunas, linhas), None
    except Exception as e:
        return None, str(e).strip()


def imprimir_tabela(colunas, linhas):
    if not linhas:
        print("(sem resultados)")
        return
    larguras = [len(str(c)) for c in colunas]
    for linha in linhas:
        for i, v in enumerate(linha):
            larguras[i] = max(larguras[i], len(str(v)))
    sep = "-+-".join("-" * w for w in larguras)
    cab = " | ".join(str(c).ljust(larguras[i]) for i, c in enumerate(colunas))
    print(cab)
    print(sep)
    for linha in linhas:
        print(" | ".join(str(v).ljust(larguras[i]) for i, v in enumerate(linha)))
    print(f"\n({len(linhas)} linha(s))")


def sanitizar_sql(texto):
    texto = texto.strip()
    if texto.startswith("```"):
        linhas = texto.split("\n")
        texto = "\n".join(linhas[1:])
    if texto.rstrip().endswith("```"):
        texto = texto.rstrip()[:-3]
    texto = texto.strip()
    if texto.upper().startswith("SQL:"):
        texto = texto[4:].strip()
    return texto


def eh_recusa(sql):
    s = sql.strip().upper()
    marcadores = (
        "IMPOSSIVEL", "IMPOSIVEL", "IMPOSSIBLE", "NAO E POSSIVEL",
        "NÃO É POSSÍVEL", "NAO POSSO", "NÃO POSSO", "DESCULPE",
        "COMO SOU UM MODELO", "COMO UM MODELO DE LINGUAGEM",
        "I'M SORRY", "I AM SORRY",
    )
    return any(s.startswith(m) or m in s[:200] for m in marcadores)


def eh_select(sql):
    s = sql.strip().upper()
    return s.startswith("SELECT") or s.startswith("WITH") or s.startswith("(")


# ============================================================
# Prompt de sistema (few-shot + regra anti-chatbot)
# ============================================================
SYSTEM_PROMPT = f"""Tarefa: converter perguntas em UMA consulta SQL PostgreSQL.

ESQUEMA DO BANCO (use APENAS estas tabelas e colunas):
{ddl}

EXEMPLOS DE ENTRADA E SAÍDA:

Pergunta: Liste os nomes de todos os eventos.
SQL: SELECT nome FROM evento;

Pergunta: Quantos participantes há em cada evento?
SQL: SELECT e.nome, COUNT(p.id_participante) AS total FROM evento e LEFT JOIN participante p ON p.id_evento = e.id_evento GROUP BY e.nome ORDER BY e.nome;

Pergunta: Quais são os palestrantes da sessão 1?
SQL: SELECT p.nome FROM palestrante pal JOIN pessoa p ON p.id_pessoa = pal.id_pessoa WHERE pal.id_sessao = 1;

Pergunta: Liste os nomes dos participantes da Semana da Computação 2026.
SQL: SELECT p.nome FROM pessoa p JOIN participante pa ON pa.id_pessoa = p.id_pessoa JOIN evento e ON e.id_evento = pa.id_evento WHERE e.nome = 'Semana da Computação 2026';

REGRAS OBRIGATÓRIAS:
1. Sua resposta é UMA única instrução SQL, começando com SELECT.
2. NUNCA escreva explicações, saudações, markdown ou crases.
3. Use APENAS tabelas e colunas do esquema acima.
4. Se for impossível responder com este esquema, responda apenas: IMPOSSIVEL: motivo curto.
5. Termine a consulta com ponto e vírgula.
6. Não diga "não tenho acesso a informações" — você é um gerador de SQL, não um chatbot.
7. Se a pergunta menciona uma coluna/atributo que não existe no esquema (ex.: idade, salário, nota, telefone quando não há), responda: IMPOSSIVEL: coluna <nome> não existe no esquema.
8. Em JOINs, cada tabela tem um alias ÚNICO (não repita o mesmo alias).
"""


# ============================================================
# Menu principal
# ============================================================
def main():
    db = config["database"]
    ollama_config = config["ollama"]

    try:
        conn = psycopg.connect(
            host=db["host"],
            port=db["port"],
            dbname=db["dbname"],
            user=db["user"],
            password=db["password"],
            autocommit=True,
        )
        print(f"[OK] PostgreSQL: {db['user']}@{db['host']}:{db['port']}/{db['dbname']}")
    except Exception as e:
        print(f"[ERRO] Falha ao conectar ao PostgreSQL: {e}")
        raise SystemExit(1)

    try:
        ollama_client = Client(host=ollama_config["host"])
        modelos = [m["model"] for m in ollama_client.list()["models"]]
        print(f"[OK] Ollama em {ollama_config['host']} (modelo: {ollama_config['model']})")
        if ollama_config["model"] not in modelos:
            print(f"[AVISO] Modelo '{ollama_config['model']}' não encontrado em {modelos}")
    except Exception as e:
        print(f"[ERRO] Falha ao conectar ao Ollama: {e}")
        raise SystemExit(1)

    print(f"[OK] {len(consultas)} consultas extraídas do Projeto.txt")

    while True:
        print("\n" + "=" * 70)
        print("MENU")
        print("=" * 70)
        for c in consultas:
            objetivo_curto = c["objetivo"][:65] + ("..." if len(c["objetivo"]) > 65 else "")
            print(f"  {c['numero']}) {objetivo_curto}")
        print("  6) Pergunta em linguagem natural (convertida em SQL via Ollama)")
        print("  0) Sair")
        print("-" * 70)

        try:
            opcao = input("Escolha uma opção: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nAté logo!")
            break

        if opcao == "0":
            print("Até logo!")
            break

        elif opcao in {str(c["numero"]) for c in consultas}:
            n = int(opcao)
            c = next(x for x in consultas if x["numero"] == n)
            print(f"\n>>> Consulta {n}: {c['objetivo']}")
            resultado, erro = executar_sql(conn, c["sql"])
            if erro:
                print(f"[ERRO] {erro}")
            else:
                colunas, linhas = resultado
                imprimir_tabela(colunas, linhas)

        elif opcao == "6":
            try:
                pergunta = input("\nDigite sua pergunta em linguagem natural: ").strip()
            except (EOFError, KeyboardInterrupt):
                print("\nCancelado.")
                continue
            if not pergunta:
                print("Pergunta vazia.")
                continue

            print("\n>>> Consultando o modelo via Ollama... (pode demorar)")
            try:
                resposta = ollama_client.chat(
                    model=ollama_config["model"],
                    messages=[
                        {"role": "system", "content": SYSTEM_PROMPT},
                        {"role": "user", "content": f"Pergunta: {pergunta}\nSQL:"},
                    ],
                    options={"temperature": 0.0},
                )
                try:
                    conteudo = resposta.message.content
                except AttributeError:
                    conteudo = resposta["message"]["content"]
            except Exception as e:
                print(f"[ERRO] Falha ao chamar o Ollama: {e}")
                continue

            sql_gerado = sanitizar_sql(conteudo)
            print(f"\n>>> SQL gerado:\n{sql_gerado}\n")

            if eh_recusa(sql_gerado):
                print("[RECUSA] O modelo indicou que a pergunta não pode ser respondida.")
                print(f"         Resposta: {sql_gerado[:200]}")
                print("         Dica: tente reformular a pergunta.")
                continue

            if not eh_select(sql_gerado):
                print("[AVISO] O SQL gerado não é SELECT. Por segurança, não será executado.")
                continue

            resultado, erro = executar_sql(conn, sql_gerado)
            if erro:
                print(f"[ERRO] Falha ao executar o SQL: {erro}")
            else:
                colunas, linhas = resultado
                imprimir_tabela(colunas, linhas)

        else:
            print("Opção inválida.")

    conn.close()


if __name__ == "__main__":
    main()
