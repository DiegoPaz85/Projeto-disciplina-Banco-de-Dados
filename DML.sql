-- ============================================================
-- SCC0640 - PROJETO DE BASES DE DADOS
-- DML.sql - Dados de teste
-- Sistema de Gestão de Eventos e Espaços
-- ============================================================
-- Este script:
--   1. Limpa todas as tabelas (permite re-executar)
--   2. Popula com dados realistas (12 pessoas, 4 eventos, 8 sessões)
--   3. Demonstra triggers 5 e 6 (lista de espera + promoção)
--   4. Demonstra trigger 4 (auditoria)
--   5. Testa triggers 1, 2, 3 com casos de falha controlados
-- ============================================================

-- ============================================================
-- PARTE 1: Limpeza
-- ============================================================
TRUNCATE TABLE
    sessao_historico,
    inscricao_sessao,
    participante,
    organizador,
    palestrante,
    evento_organizacao,
    evento_pessoa,
    espaco_recurso,
    sessao,
    atividade,
    evento,
    serie,
    espaco,
    recurso,
    pessoa,
    organizacao
RESTART IDENTITY CASCADE;

-- ============================================================
-- PARTE 2: Dados base
-- ============================================================

-- 2.1) Pessoas (12): 10 participantes (3 com múltiplos papéis) + 2 palestrantes externos
INSERT INTO pessoa (cpf, nome, email, telefone) VALUES
('111.111.111-01', 'Ana Silva',       'ana@example.com',       '(11) 91111-0001'),
('111.111.111-02', 'Bruno Costa',     'bruno@example.com',     '(11) 91111-0002'),
('111.111.111-03', 'Carla Dias',      'carla@example.com',     '(11) 91111-0003'),
('111.111.111-04', 'Daniel Lima',     'daniel@example.com',    '(11) 91111-0004'),
('111.111.111-05', 'Eduarda Rocha',   'eduarda@example.com',   '(11) 91111-0005'),
('111.111.111-06', 'Felipe Alves',    'felipe@example.com',    '(11) 91111-0006'),
('111.111.111-07', 'Gabriela Nunes',  'gabriela@example.com',  '(11) 91111-0007'),
('111.111.111-08', 'Henrique Souza',  'henrique@example.com',  '(11) 91111-0008'),
('111.111.111-09', 'Isabela Martins', 'isabela@example.com',   '(11) 91111-0009'),
('111.111.111-10', 'João Pereira',    'joao@example.com',      '(11) 91111-0010'),
('111.111.111-11', 'Karina Oliveira', 'karina@example.com',    '(11) 91111-0011'),
('111.111.111-12', 'Lucas Fernandes', 'lucas@example.com',     '(11) 91111-0012');

-- 2.2) Organizações (Q1: pessoa e organização são entidades separadas)
INSERT INTO organizacao (cnpj, nome, tipo, email) VALUES
('11.111.111/0001-11', 'Universidade de São Paulo',  'UNIVERSIDADE', 'eventos@usp.br'),
('22.222.222/0001-22', 'TechCorp Ltda',               'EMPRESA',      'contato@techcorp.com'),
('33.333.333/0001-33', 'ABCC - Assoc. Bras. de CC',   'ASSOCIACAO',   'contato@abcc.org.br');

-- 2.3) Séries (Q4: edições compartilham a série)
INSERT INTO serie (nome, descricao) VALUES
('Semana da Computação', 'Evento anual do IME-USP com palestras, workshops e minicursos.'),
('Congresso de IA',      'Congresso anual sobre Inteligência Artificial e ética.');

-- 2.4) Espaços
INSERT INTO espaco (nome, capacidade, localizacao) VALUES
('Auditório Principal', 200, 'Bloco A, térreo'),
('Sala A',               50, 'Bloco B, 1º andar'),
('Sala B',               50, 'Bloco B, 1º andar'),
('Laboratório 1',        30, 'Bloco C, 2º andar');

-- 2.5) Recursos
INSERT INTO recurso (nome, tipo) VALUES
('Projetor',         'PROJETOR'),
('Computadores',     'COMPUTADORES'),
('Sistema de Áudio', 'AUDIO'),
('Internet',         'INTERNET');

-- ============================================================
-- PARTE 3: Relacionamentos
-- ============================================================

-- 3.1) Espaço-Recurso
INSERT INTO espaco_recurso (id_espaco, id_recurso) VALUES
(1, 1), (1, 3), (1, 4),  -- Auditório: projetor, áudio, internet
(2, 1), (2, 4),          -- Sala A: projetor, internet
(3, 1),                  -- Sala B: projetor
(4, 2), (4, 4);          -- Lab 1: computadores, internet

-- 3.2) Eventos (Q4: eventos 1 e 2 são edições da mesma série; evento 4 não tem série)
INSERT INTO evento (id_serie, nome, descricao, data_inicio, data_fim) VALUES
(1,    'Semana da Computação 2026', 'Edição 2026 da Semana da Computação.',    '2026-06-01', '2026-06-12'),
(1,    'Semana da Computação 2027', 'Edição 2027 da Semana da Computação.',    '2027-06-01', '2027-06-12'),
(2,    'Congresso de IA 2026',      'Edição 2026 do Congresso de IA.',         '2026-07-15', '2026-07-17'),
(NULL, 'Workshop Avulso de Docker', 'Evento avulso, sem vínculo a uma série.', '2026-08-20', '2026-08-20');

-- 3.3) Promotores (Q1: promoção conjunta de organizações + pessoa promotora)
INSERT INTO evento_organizacao (id_evento, id_organizacao) VALUES
(1, 1), (1, 2),  -- Semana 2026: USP + TechCorp (promoção conjunta)
(2, 1),          -- Semana 2027: USP
(3, 2), (3, 3);  -- Congresso IA 2026: TechCorp + ABCC

INSERT INTO evento_pessoa (id_evento, id_pessoa) VALUES
(1, 1),  -- Semana 2026: Ana
(1, 2),  -- Semana 2026: Bruno
(3, 9),  -- Congresso IA 2026: Isabela
(4, 3);  -- Workshop Docker: Carla

-- 3.4) Atividades (Q3: título/descrição/tipo ficam na Atividade)
INSERT INTO atividade (id_evento, titulo, descricao, tipo) VALUES
(1, 'Introdução a Python',    'Minicurso básico de Python.',                 'MINICURSO'),
(1, 'Workshop de PostgreSQL', 'Workshop prático de PostgreSQL.',             'WORKSHOP'),
(1, 'IA e Futuro',            'Palestra sobre tendências em IA.',            'PALESTRA'),
(2, 'IA Avançada',            'Palestra sobre modelos avançados de IA.',     'PALESTRA'),
(3, 'Ética em IA',            'Mesa-redonda sobre ética em IA.',             'MESA_REDONDA'),
(4, 'Workshop de Docker',     'Workshop prático de Docker para iniciantes.', 'WORKSHOP');

-- 3.5) Sessões (Q3: data/hora/espaço/vagas por Sessão)
-- Sessão 3 (PostgreSQL) tem APENAS 5 VAGAS → lotação proposital para trigger 5
INSERT INTO sessao (id_atividade, id_espaco, data, hora_inicio, hora_fim, vagas_limite, exige_inscricao) VALUES
-- Sessões 1 e 2: "Introdução a Python" (duas sessões — Q3)
(1, 2, '2026-06-10', '09:00', '12:00',  50, FALSE),
(1, 2, '2026-06-11', '09:00', '12:00',  50, FALSE),
-- Sessões 3 e 4: "Workshop de PostgreSQL" (2 sessões, 5 vagas, exige inscrição)
(2, 4, '2026-06-10', '14:00', '17:00',   5, TRUE),
(2, 4, '2026-06-11', '14:00', '17:00',   5, TRUE),
-- Sessão 5: palestra do evento 1
(3, 1, '2026-06-12', '10:00', '12:00', 200, FALSE),
-- Sessão 6: palestra do evento 2
(4, 1, '2027-06-10', '10:00', '12:00', 200, FALSE),
-- Sessão 7: mesa-redonda do evento 3
(5, 1, '2026-07-15', '15:00', '17:00', 200, FALSE),
-- Sessão 8: workshop avulso
(6, 3, '2026-08-20', '09:00', '12:00',  30, TRUE);

-- 3.6) Participantes (Q2: papel ligado ao evento)
INSERT INTO participante (id_pessoa, id_evento, data_inscricao) VALUES
(1, 1, '2026-04-01 10:00:00'),  -- id 1: Ana
(2, 1, '2026-04-01 10:01:00'),  -- id 2: Bruno
(3, 1, '2026-04-02 10:02:00'),  -- id 3: Carla
(4, 1, '2026-04-02 10:03:00'),  -- id 4: Daniel
(5, 1, '2026-04-03 10:04:00'),  -- id 5: Eduarda
(6, 1, '2026-04-03 10:05:00'),  -- id 6: Felipe
(7, 1, '2026-04-04 10:06:00'),  -- id 7: Gabriela
(8, 1, '2026-04-04 10:07:00'),  -- id 8: Henrique
(9, 3, '2026-05-01 10:00:00'),  -- id 9: Isabela
(10,3, '2026-05-01 10:01:00');  -- id 10: João

-- 3.7) Organizadores (Q2: pessoa pode organizar)
INSERT INTO organizador (id_pessoa, id_evento, funcao) VALUES
(1, 1, 'Coordenadora geral'),
(2, 1, 'Coordenação técnica'),
(3, 4, 'Organizadora');

-- 3.8) Palestrantes (Q2: palestrante ligado à Sessão)
-- Bruno é participante E palestrante simultaneamente (Q2)
-- Isabela é participante E palestrante simultaneamente (Q2)
INSERT INTO palestrante (id_pessoa, id_sessao) VALUES
(11, 1),  -- Karina → Sessão 1
(11, 2),  -- Karina → Sessão 2
(2, 3),   -- Bruno  → Sessão 3
(12, 3),  -- Lucas  → Sessão 3
(9, 7);   -- Isabela → Sessão 7

-- ============================================================
-- PARTE 4: Demonstração dos triggers 5 e 6 (lista de espera)
-- ============================================================

-- 4.1) 8 participantes tentam se inscrever na Sessão 3 (5 vagas)
-- Trigger 5 (BEFORE INSERT) distribui automaticamente:
--   primeiros 5 → CONFIRMADA; próximos 3 → ESPERA
INSERT INTO inscricao_sessao (id_participante, id_sessao, status, data_inscricao) VALUES
(1, 3, 'CONFIRMADA', '2026-05-01 10:00:00'),  -- id 1: Ana      → CONFIRMADA
(2, 3, 'CONFIRMADA', '2026-05-01 10:01:00'),  -- id 2: Bruno    → CONFIRMADA
(3, 3, 'CONFIRMADA', '2026-05-01 10:02:00'),  -- id 3: Carla    → CONFIRMADA
(4, 3, 'CONFIRMADA', '2026-05-01 10:03:00'),  -- id 4: Daniel   → CONFIRMADA
(5, 3, 'CONFIRMADA', '2026-05-01 10:04:00'),  -- id 5: Eduarda  → CONFIRMADA
(6, 3, 'CONFIRMADA', '2026-05-01 10:05:00'),  -- id 6: Felipe   → ESPERA (trigger 5)
(7, 3, 'CONFIRMADA', '2026-05-01 10:06:00'),  -- id 7: Gabriela → ESPERA (trigger 5)
(8, 3, 'CONFIRMADA', '2026-05-01 10:07:00');  -- id 8: Henrique → ESPERA (trigger 5)

-- 4.2) Estado APÓS as inscrições (esperado: 5 CONFIRMADA + 3 ESPERA)
SELECT '=== [Trigger 5] Estado APOS inscricoes na Sessao 3 ===' AS momento;
SELECT id_inscricao, id_participante, status, data_inscricao
FROM inscricao_sessao
WHERE id_sessao = 3
ORDER BY id_inscricao;

-- 4.3) Carla (id_inscricao 3) cancela
-- Trigger 6 (AFTER UPDATE) promove automaticamente o primeiro da ESPERA
UPDATE inscricao_sessao
SET status = 'CANCELADA'
WHERE id_inscricao = 3;

-- 4.4) Estado APÓS o cancelamento (esperado: Felipe promovido de ESPERA → CONFIRMADA)
SELECT '=== [Trigger 6] Estado APOS cancelamento de Carla (Sessao 3) ===' AS momento;
SELECT id_inscricao, id_participante, status, data_inscricao
FROM inscricao_sessao
WHERE id_sessao = 3
ORDER BY id_inscricao;

-- ============================================================
-- PARTE 5: Demonstração do trigger 4 (auditoria)
-- ============================================================

SELECT '=== [Trigger 4] Estado ANTES da alteracao (Sessao 3) ===' AS momento;
SELECT id_sessao, data, hora_inicio, hora_fim, id_espaco
FROM sessao WHERE id_sessao = 3;

UPDATE sessao
SET hora_inicio = '15:00', hora_fim = '18:00'
WHERE id_sessao = 3;

SELECT '=== [Trigger 4] Estado DEPOIS da alteracao (Sessao 3) ===' AS momento;
SELECT id_sessao, data, hora_inicio, hora_fim, id_espaco
FROM sessao WHERE id_sessao = 3;

SELECT '=== [Trigger 4] Historico gerado automaticamente ===' AS momento;
SELECT id_historico, data, hora_inicio, hora_fim, id_espaco, alterado_em
FROM sessao_historico WHERE id_sessao = 3
ORDER BY id_historico;

-- ============================================================
-- PARTE 6: Testes dos triggers 1, 2, 3 (devem FALHAR)
-- ============================================================
-- Cada teste é isolado num DO block com EXCEPTION handler.
-- Se o trigger levantar exceção → [OK]; se não → [FALHA].
-- ============================================================

-- 6.1) Trigger 1: vagas_limite > capacidade do espaço (Sala A tem cap=50)
DO $$
BEGIN
    INSERT INTO sessao (id_atividade, id_espaco, data, hora_inicio, hora_fim, vagas_limite, exige_inscricao)
    VALUES (4, 2, '2027-06-11', '09:00', '12:00', 100, TRUE);
    RAISE NOTICE '[FALHA] Trigger 1 nao disparou!';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[OK] Trigger 1 barrou INSERT invalido: %', SQLERRM;
END $$;

-- 6.2) Trigger 2: conflito de horário no mesmo espaço
-- Sala A já tem Sessão 1 das 09h-12h em 10/06/2026
DO $$
BEGIN
    INSERT INTO sessao (id_atividade, id_espaco, data, hora_inicio, hora_fim)
    VALUES (4, 2, '2026-06-10', '10:00', '11:00');
    RAISE NOTICE '[FALHA] Trigger 2 nao disparou!';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[OK] Trigger 2 barrou conflito de espaco: %', SQLERRM;
END $$;

-- 6.3) Trigger 3: conflito de horário do palestrante
-- Karina (id 11) já palestra Sessão 1 (10/06 09h-12h)
DO $$
DECLARE
    v_id INTEGER;
BEGIN
    INSERT INTO sessao (id_atividade, id_espaco, data, hora_inicio, hora_fim)
    VALUES (4, 3, '2026-06-10', '10:00', '11:00')
    RETURNING id_sessao INTO v_id;

    BEGIN
        INSERT INTO palestrante (id_pessoa, id_sessao) VALUES (11, v_id);
        RAISE NOTICE '[FALHA] Trigger 3 nao disparou!';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[OK] Trigger 3 barrou conflito de palestrante: %', SQLERRM;
    END;

    DELETE FROM sessao WHERE id_sessao = v_id;
END $$;

-- ============================================================
-- PARTE 7: Resumo final
-- ============================================================
SELECT '=== RESUMO FINAL ===' AS secao;
SELECT 'Pessoas'                AS tabela, COUNT(*) AS total FROM pessoa
UNION ALL SELECT 'Organizacoes',          COUNT(*) FROM organizacao
UNION ALL SELECT 'Series',                COUNT(*) FROM serie
UNION ALL SELECT 'Eventos',               COUNT(*) FROM evento
UNION ALL SELECT 'Atividades',            COUNT(*) FROM atividade
UNION ALL SELECT 'Sessoes',               COUNT(*) FROM sessao
UNION ALL SELECT 'Espacos',               COUNT(*) FROM espaco
UNION ALL SELECT 'Recursos',              COUNT(*) FROM recurso
UNION ALL SELECT 'Participantes',         COUNT(*) FROM participante
UNION ALL SELECT 'Organizadores',         COUNT(*) FROM organizador
UNION ALL SELECT 'Palestrantes',          COUNT(*) FROM palestrante
UNION ALL SELECT 'Inscricoes em sessao',  COUNT(*) FROM inscricao_sessao
UNION ALL SELECT 'Historico de sessao',   COUNT(*) FROM sessao_historico;
