CREATE TABLE IF NOT EXISTS dbmigrate.flower (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    color       VARCHAR(50),
    fragrance   VARCHAR(50),
    quantity    INTEGER NOT NULL DEFAULT 0,
    price       NUMERIC(10,2),
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
