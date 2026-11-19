CREATE TABLE colaboradores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha VARCHAR(50) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL
);

CREATE TABLE tarefas (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    id_colaborador INT REFERENCES colaboradores(id),
    id_categoria INT REFERENCES categorias(id),
    data_criacao TIMESTAMP,
    data_entrega DATE NOT NULL,
    status VARCHAR(30) CHECK (status IN ('Pendente', 'Em andamento', 'Concluída'))
);

CREATE TABLE historico_tarefas (
    id SERIAL PRIMARY KEY,
    id_tarefa INT REFERENCES tarefas(id),
    descricao TEXT,
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO colaboradores (nome, email, senha, ativo) VALUES
('João', 'joao@gmail.com', '123', TRUE),
('Maria', 'maria@gmail.com', '123', TRUE),
('Pedro', 'pedro@gmail.com', '123', FALSE);

INSERT INTO categorias (nome) VALUES
('Estudo'),
('Trabalho'),
('Projeto');

INSERT INTO tarefas (titulo, id_colaborador, id_categoria, data_entrega, status) VALUES
('Estudar SQL', 1, 1, '2026-11-25', 'Pendente'),
('Criar site', 2, 3, '2026-11-22', 'Em andamento'),
('Fazer relatório', 1, 2, '2026-11-30', 'Concluída');

CREATE OR REPLACE FUNCTION fn_buscar_colaboradores(termo TEXT)
RETURNS TABLE (nome VARCHAR, email VARCHAR)
AS $$
BEGIN
    RETURN QUERY
    SELECT c.nome, c.email
    FROM colaboradores c
    WHERE c.nome ILIKE '%' || termo || '%'
    OR c.email ILIKE '%' || termo || '%';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_validar_tarefa()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM colaboradores
        WHERE id = NEW.id_colaborador AND ativo = TRUE
    ) THEN
        RAISE EXCEPTION 'Colaborador inativo!';
    END IF;

    NEW.data_criacao = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_tarefa
BEFORE INSERT ON tarefas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_tarefa();

CREATE OR REPLACE FUNCTION fn_historico()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_tarefas (id_tarefa, descricao)
    VALUES (NEW.id, 'Tarefa criada');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_historico
AFTER INSERT ON tarefas
FOR EACH ROW
EXECUTE FUNCTION fn_historico();

CREATE VIEW vw_painel_principal AS
SELECT
    c.nome AS colaborador,
    t.titulo,
    cat.nome AS categoria,
    t.data_entrega,
    t.status
FROM tarefas t
JOIN colaboradores c ON t.id_colaborador = c.id
JOIN categorias cat ON t.id_categoria = cat.id;

CREATE VIEW vw_cronograma_prazos AS
SELECT
    t.titulo,
    t.status,
    t.data_entrega,
    t.data_entrega - CURRENT_DATE AS dias_restantes,
    c.nome AS responsavel
FROM tarefas t
JOIN colaboradores c ON t.id_colaborador = c.id
ORDER BY t.data_entrega ASC;

SELECT * FROM colaboradores;
SELECT * FROM categorias;
SELECT * FROM tarefas;
SELECT * FROM historico_tarefas;
SELECT * FROM vw_painel_principal;
SELECT * FROM vw_cronograma_prazos;
SELECT * FROM fn_buscar_colaboradores('João');
