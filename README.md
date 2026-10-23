#  Sistema de Gestão de Eventos e Espaços

> Projeto da disciplina **SCC0640 / SCC0540 — Bases de Dados** (2026-2)
> Sistema completo de gestão de eventos, espaços, atividades e inscrições,
> com banco PostgreSQL, triggers de integridade e protótipo Python integrado
> a um LLM local via Ollama.

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)](https://www.postgresql.org/)
[![Python](https://img.shields.io/badge/Python-3.11+-green)](https://www.python.org/)
[![Ollama](https://img.shields.io/badge/Ollama-local-orange)](https://ollama.com/)

---

##  Índice

- [Visão geral](#-visão-geral)
- [Funcionalidades](#-funcionalidades)
- [Arquitetura](#-arquitetura)
- [Estrutura do projeto](#-estrutura-do-projeto)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação rápida (TL;DR)](#-instalação-rápida-tldr)
- [Instalação detalhada](#-instalação-detalhada)
- [Como usar o protótipo](#-como-usar-o-protótipo)
- [Decisões de projeto](#-decisões-de-projeto)
- [Destaques técnicos](#-destaques-técnicos)
- [Equipe](#-equipe)
- [Limitações conhecidas](#-limitações-conhecidas)
- [Contexto acadêmico](#-contexto-acadêmico)

---

##  Visão geral

O sistema permite:

- Cadastrar **eventos** com séries/edições (ex.: "Semana da Computação 2026" e "2027")
- Gerenciar **pessoas** e **organizações** promotoras
- Estruturar a **programação** em atividades e sessões (com data, horário e espaço)
- Controlar **espaços** e seus recursos (projetor, computadores, internet...)
- Registrar **participantes** no evento e inscrições adicionais em sessões
- Gerenciar **listas de espera** automáticas (quando sessões lotam)
- Manter **histórico de alterações** de programação das sessões

A integração com **LLM local** (via Ollama) permite que o usuário faça **perguntas em linguagem natural** que são convertidas automaticamente em SQL e executadas contra o banco.

---

##  Funcionalidades

### Banco de dados

- **16 tabelas** em PostgreSQL 16 com:
  - Chaves primárias simples e compostas
  - Chaves estrangeiras com `ON DELETE`/`ON UPDATE` configurados
  - Constraints `UNIQUE`, `NOT NULL`, `CHECK`, `DEFAULT`
  - **Coluna gerada** (`sessao.duracao` = `hora_fim - hora_inicio`)
  - **6 tipos ENUM** para classificação (atividade, status de inscrição, recurso)

### Triggers (6 finalidades distintas)

| Trigger | Momento | Finalidade |
|---------|---------|------------|
| `trg_valida_capacidade_sessao` | BEFORE INSERT/UPDATE em `sessao` | `vagas_limite ≤ capacidade` do espaço |
| `trg_conflito_espaco` | BEFORE INSERT/UPDATE em `sessao` | Impede duas sessões no mesmo espaço em horários sobrepostos |
| `trg_conflito_palestrante` | BEFORE INSERT/UPDATE em `palestrante` | Impede palestrante em duas sessões simultâneas |
| `trg_historico_sessao` | AFTER UPDATE em `sessao` | Grava estado anterior em `sessao_historico` (auditoria) |
| `trg_controla_inscricao` | BEFORE INSERT em `inscricao_sessao` | Valida evento + joga para ESPERA se lotado |
| `trg_promove_espera` | AFTER UPDATE em `inscricao_sessao` | Promove primeiro da fila quando há cancelamento |

### Consultas (5 níveis de complexidade)

| # | Tema | Técnicas SQL |
|---|------|--------------|
| 1 | Promotores de eventos | `UNION ALL`, `LEFT JOIN` |
| 2 | Taxa de ocupação por sessão | `FILTER (WHERE ...)`, `NULLIF`, `HAVING` |
| 3 | Status de inscrições por participante | Agregações condicionais múltiplas |
| 4 | Duração total da programação por evento | `CTE`, `EXTRACT(EPOCH)`, agregação segura |
| 5 | Ranking de eventos por participantes | `RANK() OVER (...)`, subquery correlacionada |

### Protótipo Python

- Menu interativo em CLI
- Executa as **5 consultas pré-definidas**
- Recebe **pergunta em linguagem natural** e converte em SQL via Ollama
- **Sanitização** de resposta do LLM (remove markdown, prefixos)
- **Barreira de segurança** (bloqueia `DELETE`/`DROP`/`UPDATE`)
- Tratamento de erros sem abortar o programa

---

##  Arquitetura

```
┌─────────────────┐
│   Usuário       │
│  (terminal)     │
└────────┬────────┘
         │ python main.py
         ▼
┌─────────────────┐     HTTP      ┌──────────────┐
│   main.py       │──────────────▶│   Ollama     │
│   (Python)      │◀──────────────│  (LLM local) │
│                 │   SQL gerado  └──────────────┘
│                 │
│                 │   psycopg    ┌──────────────┐
│                 │─────────────▶│ PostgreSQL   │
│                 │◀─────────────│  (Docker)    │
└─────────────────┘   resultado  └──────────────┘
```

O `main.py` extrai o DDL e as 5 consultas diretamente do `Projeto.txt` (fonte única de verdade) e usa o `config.json` para saber onde estão o banco e o Ollama.

---

##  Estrutura do projeto

```
ProjetoBD/
├── README.md                  ← este arquivo
├── Instrucoes.txt             ← instruções para o avaliador
├── Projeto.txt                ← documento de entrega (decisões + DDL + consultas)
├── DML.sql                    ← dados de teste
│
├── ER.drawio.pdf              ← diagrama E/R (visualização)
├── ER.xml                     ← diagrama E/R (fonte draw.io)
├── Relacional.pdf             ← modelo relacional (Crow's Foot)
├── Relacional.mmd             ← modelo relacional (fonte mermaid)
│
└── Prototipo/
    ├── main.py                ← protótipo Python
    ├── config.json            ← configuração de DB e Ollama
    └── requirements.txt       ← dependências Python
```

---

##  Pré-requisitos

- **Docker** (para PostgreSQL e Ollama em containers)
- **Python 3.11+** com `pip` e `venv`
- **~3 GB de RAM livre** para o modelo `gemma3:1b`
- Sistema Linux/macOS/Windows com Docker funcional

Verifique as versões:

```bash
docker --version       # Docker 2x.x
python3 --version      # Python 3.11+
```

---

##  Instalação rápida (TL;DR)

Para quem já tem Docker e Python configurados:

```bash
# 1. Clonar
git clone <URL_DO_REPO>
cd ProjetoBD

# 2. Subir PostgreSQL
docker run -d --name postgres-eventos \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=eventos -p 5432:5432 \
  -v postgres-eventos-data:/var/lib/postgresql/data \
  postgres:16

# 3. Subir Ollama e baixar modelo
docker run -d --name ollama -v ollama:/root/.ollama \
  -p 11434:11434 ollama/ollama
docker exec -it ollama ollama pull gemma3:1b

# 4. Criar DDL
cd Prototipo
python3 -c "from pathlib import Path; t=Path('../Projeto.txt').read_text(); \
  print(t.split('3. DDL COMPLETO',1)[1].split('4. CONSULTAS',1)[0].strip())" \
  | docker exec -i postgres-eventos psql -U postgres -d eventos

# 5. Carregar DML
docker exec -i postgres-eventos psql -U postgres -d eventos -v ON_ERROR_STOP=1 < ../DML.sql

# 6. Instalar dependências e rodar
python3 -m venv .venv && source .venv/bin/activate
python -m pip install -r requirements.txt
python main.py
```

---

##  Instalação detalhada

### 1. Clonar o repositório

```bash
git clone <URL_DO_REPO>
cd ProjetoBD
```

### 2. Subir o PostgreSQL em Docker

```bash
docker run -d \
  --name postgres-eventos \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=eventos \
  -p 5432:5432 \
  -v postgres-eventos-data:/var/lib/postgresql/data \
  --restart unless-stopped \
  postgres:16
```

Verificar:

```bash
docker ps --filter name=postgres-eventos
# esperado: Up X seconds
```

>  **Atenção:** se você já tiver PostgreSQL instalado diretamente no sistema (via `apt`), pare-o antes:
> ```bash
> sudo systemctl stop postgresql
> sudo systemctl disable postgresql
> ```

### 3. Subir o Ollama e baixar o modelo

```bash
docker run -d \
  --name ollama \
  -v ollama:/root/.ollama \
  -p 11434:11434 \
  --restart unless-stopped \
  ollama/ollama

docker exec -it ollama ollama pull gemma3:1b
```

Verificar:

```bash
curl http://localhost:11434/api/tags
# esperado: {"models":[{"name":"gemma3:1b",...}]}
```

>  **Escolha de modelo:** `gemma3:1b` (~800 MB) foi escolhido por caber em máquinas com pouca RAM. Se sua máquina tiver 8+ GB livres, considere `qwen2.5-coder:3b` (melhor em SQL) ou `qwen3:8b`. Para trocar, basta editar `Prototipo/config.json` após baixar.

### 4. Criar o schema (DDL)

O DDL está embutido em `Projeto.txt` (seção "3. DDL COMPLETO"). O protótipo o extrai automaticamente, mas você pode executá-lo manualmente para inspeção:

```bash
cd ProjetoBD
python3 -c "from pathlib import Path; t=Path('Projeto.txt').read_text(); \
  print(t.split('3. DDL COMPLETO',1)[1].split('4. CONSULTAS',1)[0].strip())" \
  | docker exec -i postgres-eventos psql -U postgres -d eventos -v ON_ERROR_STOP=1
```

Verificar que as 16 tabelas e 6 triggers foram criados:

```bash
docker exec -it postgres-eventos psql -U postgres -d eventos -c "
SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename;"

docker exec -it postgres-eventos psql -U postgres -d eventos -c "
SELECT DISTINCT trigger_name FROM information_schema.triggers ORDER BY trigger_name;"
```

### 5. Carregar dados de teste (DML)

```bash
docker exec -i postgres-eventos psql -U postgres -d eventos -v ON_ERROR_STOP=1 < DML.sql
```

O DML é **re-executável** (começa com `TRUNCATE ... RESTART IDENTITY CASCADE`) e imprime:
- Estado das inscrições antes/depois dos triggers 5 e 6
- Histórico gerado pelo trigger 4
- `NOTICE [OK]` confirmando que os triggers 1, 2, 3 barraram operações inválidas
- Resumo com `COUNT(*)` de todas as tabelas

### 6. Instalar dependências do Python

```bash
cd Prototipo
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

>  Em Ubuntu 24.04+, `pip install` global é bloqueado (PEP 668). O `venv` é obrigatório.

### 7. Executar o protótipo

```bash
python main.py
```

---

##  Como usar o protótipo

Ao iniciar, você verá:

```
[OK] PostgreSQL: postgres@localhost:5432/eventos
[OK] Ollama em http://localhost:11434 (modelo: gemma3:1b)
[OK] 5 consultas extraídas do Projeto.txt

======================================================================
MENU
======================================================================
  1) Listar todos os eventos com seus respectivos promotores...
  2) Listar as sessões com taxa de ocupação superior a 40%...
  3) Listar todos os participantes com a contagem de inscrições...
  4) Calcular a duração total da programação de cada evento...
  5) Produzir um ranking dos eventos por número de participantes...
  6) Pergunta em linguagem natural (convertida em SQL via Ollama)
  0) Sair
----------------------------------------------------------------------
Escolha uma opção:
```

### Opções 1–5 — Consultas pré-definidas

Digite o número e veja o resultado em tabela.

### Opção 6 — Pergunta em linguagem natural

Digite `6`, depois sua pergunta. Exemplos que funcionam bem:

- `Liste os nomes de todos os eventos`
- `Liste os nomes dos participantes da Semana da Computação 2026`
- `Quais são os palestrantes da sessão 1?`

O protótipo:
1. Envia a pergunta + schema + 4 exemplos (few-shot) ao Ollama
2. Recebe o SQL gerado
3. **Sanitiza** (remove markdown/crases)
4. **Valida** (só aceita `SELECT`/`WITH`)
5. Executa e mostra o resultado — ou o erro

### Perguntas que devem ser recusadas

- `Delete todos os participantes` → `[AVISO] O SQL gerado não é SELECT`
- `Drop table pessoa` → `[AVISO] O SQL gerado não é SELECT`

### Perguntas que geram erro explícito

- `Qual a média de idade dos participantes?` → `[ERRO] column "idade" does not exist`

O erro é **do PostgreSQL**, não silencioso — o SQL nunca executa com dados errados.

---

##  Decisões de projeto

As 6 decisões de modelagem que guiaram o banco:

| Q | Tema | Decisão |
|---|------|---------|
| **Q1** | Promotores | `Pessoa` e `Organizacao` são entidades separadas, ligadas a `Evento` por dois N:N. Permite múltiplos promotores simultâneos. |
| **Q2** | Papéis | `Participante` e `Organizador` ligados a **Evento**; `Palestrante` ligado a **Sessão**. Uma pessoa pode ter os três papéis ao mesmo tempo. |
| **Q3** | Atividade × Sessão | `Atividade` guarda título/descrição/tipo; `Sessao` guarda data/hora/espaço/vagas. Carga horária calculada por `SUM`. |
| **Q4** | Edições | Entidade `Serie` opcional (`id_serie NULL`) guarda o compartilhado. Nome do evento é livre. `ON DELETE SET NULL`. |
| **Q5** | Vagas e inscrições | `vagas_limite ≤ capacidade` por trigger. Lista de espera automática. Cancelamento promove o próximo da fila. |
| **Q6** | Alterações de programação | Histórico em `sessao_historico`, populado por trigger `AFTER UPDATE` em `sessao`. |

Detalhes completos em `Projeto.txt`, seção "2. DECISOES DE PROJETO".

---

##  Destaques técnicos

### Consulta 5 — `RANK()` para ranking

```sql
WITH resumo AS (
    SELECT e.id_evento, e.nome, e.data_inicio,
           COUNT(DISTINCT a.id_atividade) AS atividades,
           COUNT(DISTINCT s.id_sessao) AS sessoes,
           (SELECT COUNT(*) FROM participante p WHERE p.id_evento = e.id_evento) AS participantes
    FROM evento e
    LEFT JOIN atividade a ON a.id_evento = e.id_evento
    LEFT JOIN sessao s ON s.id_atividade = a.id_atividade
    GROUP BY e.id_evento, e.nome, e.data_inicio
)
SELECT RANK() OVER (ORDER BY participantes DESC) AS posicao, ...
```

**Por que `RANK` e não `ROW_NUMBER`:** eventos empatados em número de participantes recebem **a mesma posição** (3º e 3º, em vez de 3º e 4º).

**Por que CTE + subquery correlacionada:** se fizéssemos `COUNT(participante)` no mesmo `GROUP BY`, o `JOIN` com atividade×sessão multiplicaria os participantes. Separar em CTEs isola cada agregação.

### Prompt engineering para LLM pequeno

O `gemma3:1b` (1 bilhão de parâmetros) tende a "conversar" em vez de gerar SQL. A solução foi **few-shot prompting** — 4 exemplos no formato exato:

```
Pergunta: Liste os nomes de todos os eventos.
SQL: SELECT nome FROM evento;

Pergunta: Quantos participantes há em cada evento?
SQL: SELECT e.nome, COUNT(p.id_participante) ...
```

Com os exemplos, o modelo "completa o padrão" em vez de improvisar. Teste B antes/depois:
- **Antes:** `"Compreendo sua solicitação, mas como sou um modelo..."` ❌
- **Depois:** `SELECT nome FROM evento;` ✅

---

##  Equipe

| Nome |
|------|------|
| Diego Soares da Paz|
| [preencher] | [preencher] |
| [preencher] | [preencher] |
| [preencher] | [preencher] |
| [preencher] | [preencher] |

**Disciplina:** SCC0640 / SCC0540 — Bases de Dados
**Professor(a):** Junior
**Semestre:** 2026-2

---

## ⚠️ Limitações conhecidas

- **Modelo pequeno** (`gemma3:1b`): pode ocasionalmente inventar colunas inexistentes em perguntas complexas. O protótipo trata como erro do PostgreSQL (não executa silenciosamente). Modelos maiores (`qwen2.5-coder:3b`, `qwen3:8b`) funcionam melhor, mas exigem mais RAM.
- **Trigger de conflito de palestrante**: dispara no cadastro do palestrante, não quando uma sessão muda de horário. Melhoria futura: replicar a lógica em `UPDATE` de `sessao`.
- **`sessao_historico.id_espaco` sem FK**: decisão consciente — histórico de auditoria deve sobreviver à remoção do espaço referenciado.

---

##  Contexto acadêmico

**Disciplina:** SCC0640 / SCC0540 — Bases de Dados
**Tecnologias obrigatórias:** PostgreSQL, Python 3.11+, Ollama
**Requisitos atendidos:**
- ✅ Modelagem E/R (draw.io) + modelo relacional (mermaid)
- ✅ DDL com PK, FK, UNIQUE, NOT NULL, CHECK, DEFAULT, colunas geradas, ON DELETE/UPDATE
- ✅ 4+ triggers (temos 6, com finalidades distintas)
- ✅ DML com dados de teste
- ✅ 5 consultas com complexidades variadas
- ✅ Protótipo Python com integração LLM local
- ✅ Conversão NL→SQL via Ollama
- ✅ Estrutura portável (só `config.json` precisa ser editado)

**Como contribuir:** veja [`CONTRIBUTING.md`](CONTRIBUTING.md) (em breve nos cinemas...).

---

##  Licença

Projeto acadêmico — uso educacional. Consulte o enunciado da disciplina para políticas de plágio e colaboração.
