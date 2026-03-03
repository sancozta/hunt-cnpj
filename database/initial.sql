-- CNPJ Data Pipeline - Database Schema
-- Run automatically on first docker compose up

-- ============================================================================
-- Reference Tables (Tabelas de Referência)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pj_activity_codes ( -- cnaes
    code VARCHAR(7) PRIMARY KEY, -- codigo
    description TEXT, -- descricao
    created_at TIMESTAMP DEFAULT NOW() NOT NULL, -- data_criacao
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL -- data_atualizacao
);

CREATE TABLE IF NOT EXISTS pj_status_reasons ( -- motivos
    code VARCHAR(2) PRIMARY KEY, -- codigo
    description TEXT, -- descricao
    created_at TIMESTAMP DEFAULT NOW() NOT NULL, -- data_criacao
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL -- data_atualizacao
);

CREATE TABLE IF NOT EXISTS pj_cities ( -- municipios
    code VARCHAR(7) PRIMARY KEY, -- codigo
    description TEXT, -- descricao
    created_at TIMESTAMP DEFAULT NOW() NOT NULL, -- data_criacao
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL -- data_atualizacao
);

CREATE TABLE IF NOT EXISTS pj_legal_natures ( -- naturezas_juridicas
    code VARCHAR(4) PRIMARY KEY, -- codigo
    description TEXT, -- descricao
    created_at TIMESTAMP DEFAULT NOW() NOT NULL, -- data_criacao
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL -- data_atualizacao
);

CREATE TABLE IF NOT EXISTS pj_countries ( -- paises
    code VARCHAR(3) PRIMARY KEY, -- codigo
    description TEXT, -- descricao
    created_at TIMESTAMP DEFAULT NOW() NOT NULL, -- data_criacao
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL -- data_atualizacao
);

CREATE TABLE IF NOT EXISTS pj_partner_qualifications ( -- qualificacoes_socios
    code VARCHAR(2) PRIMARY KEY, -- codigo
    description TEXT, -- descricao
    created_at TIMESTAMP DEFAULT NOW() NOT NULL, -- data_criacao
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL -- data_atualizacao
);

-- ============================================================================
-- Main Tables (Tabelas Principais)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pj_companies ( -- empresas
    cnpj VARCHAR(8) PRIMARY KEY, -- cnpj_basico
    social_reason_name TEXT, -- razao_social
    legal_nature_name VARCHAR(4), -- natureza_juridica
    responsible_qualification VARCHAR(2), -- qualificacao_responsavel
    social_capital DOUBLE PRECISION, -- capital_social
    company_size VARCHAR(2), -- porte
    responsible_federative_entity TEXT, -- ente_federativo_responsavel
    created_at TIMESTAMP DEFAULT NOW() NOT NULL, -- data_criacao
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL -- data_atualizacao
);

CREATE TABLE IF NOT EXISTS pj_establishments ( -- estabelecimentos
    cnpj VARCHAR(8) NOT NULL, -- cnpj_basico
    cnpj_establishment VARCHAR(4) NOT NULL, -- cnpj_ordem
    cnpj_check_digit VARCHAR(2) NOT NULL, -- cnpj_dv
    filial_identifier INTEGER, -- identificador_matriz_filial
    fantasy_name TEXT, -- nome_fantasia
    status VARCHAR(2), -- situacao_cadastral
    status_date DATE, -- data_situacao_cadastral
    status_reason VARCHAR(2), -- motivo_situacao_cadastral
    exterior_city_name TEXT, -- nome_cidade_exterior
    country VARCHAR(3), -- pais
    activity_start_date DATE, -- data_inicio_atividade
    cnae_primary VARCHAR(7), -- cnae_fiscal_principal
    cnae_secondary TEXT, -- cnae_fiscal_secundaria
    street_type TEXT, -- tipo_logradouro
    street TEXT, -- logradouro
    number TEXT, -- numero
    complement TEXT, -- complemento
    district TEXT, -- bairro
    zip_code VARCHAR(8), -- cep
    state VARCHAR(2), -- uf
    city VARCHAR(7), -- municipio
    area_code_primary VARCHAR(4), -- ddd_1
    phone_primary VARCHAR(8), -- telefone_1
    area_code_secondary VARCHAR(4), -- ddd_2
    phone_secondary VARCHAR(8), -- telefone_2
    fax_area_code VARCHAR(4), -- ddd_fax
    fax VARCHAR(8), -- fax
    email TEXT, -- correio_eletronico
    special_status TEXT, -- situacao_especial
    special_status_date DATE, -- data_situacao_especial
    created_at TIMESTAMP DEFAULT NOW() NOT NULL, -- data_criacao
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL, -- data_atualizacao
    PRIMARY KEY (cnpj, cnpj_establishment, cnpj_check_digit)
);

CREATE TABLE IF NOT EXISTS pj_partners ( -- socios
    cnpj VARCHAR(8) NOT NULL, -- cnpj_basico
    partner_type VARCHAR(1) NOT NULL, -- identificador_de_socio
    partner_name TEXT, -- nome_socio
    partner_document VARCHAR(14) NOT NULL, -- cnpj_cpf_do_socio
    partner_qualification VARCHAR(2), -- qualificacao_do_socio
    entry_date DATE, -- data_entrada_sociedade
    country VARCHAR(3), -- pais
    legal_representative VARCHAR(11), -- representante_legal
    representative_name TEXT, -- nome_do_representante
    representative_qualification VARCHAR(2), -- qualificacao_do_representante_legal
    age_range VARCHAR(1), -- faixa_etaria
    created_at TIMESTAMP DEFAULT NOW() NOT NULL, -- data_criacao
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL, -- data_atualizacao
    PRIMARY KEY (cnpj, partner_type, partner_document)
);

CREATE TABLE IF NOT EXISTS pj_simples_nacional ( -- dados_simples
    cnpj VARCHAR(8) PRIMARY KEY, -- cnpj_basico
    simples_option VARCHAR(1), -- opcao_pelo_simples
    simples_option_date DATE, -- data_opcao_pelo_simples
    simples_exclusion_date DATE, -- data_exclusao_do_simples
    mei_option VARCHAR(1), -- opcao_pelo_mei
    mei_option_date DATE, -- data_opcao_pelo_mei
    mei_exclusion_date DATE, -- data_exclusao_do_mei
    created_at TIMESTAMP DEFAULT NOW() NOT NULL, -- data_criacao
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL -- data_atualizacao
);

-- ============================================================================
-- Tracking Table (Tabela de Controle)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pj_processed_files ( -- processed_files
    directory VARCHAR(50) NOT NULL,
    filename VARCHAR(255) NOT NULL,
    processed_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (directory, filename)
);

-- ============================================================================
-- Indexes (Índices)
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_pj_establishments_state ON pj_establishments(state); -- uf
CREATE INDEX IF NOT EXISTS idx_pj_establishments_city ON pj_establishments(city); -- municipio
CREATE INDEX IF NOT EXISTS idx_pj_establishments_status ON pj_establishments(status); -- situacao_cadastral
CREATE INDEX IF NOT EXISTS idx_pj_establishments_cnae ON pj_establishments(cnae_primary); -- cnae_fiscal_principal
CREATE INDEX IF NOT EXISTS idx_pj_partners_cnpj ON pj_partners(cnpj); -- cnpj_basico
