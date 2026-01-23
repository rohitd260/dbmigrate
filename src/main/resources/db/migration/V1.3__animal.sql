
CREATE TABLE IF NOT EXISTS dbmigrate.animal (
    id           BIGSERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    species      VARCHAR(100) NOT NULL,
    age          INTEGER CHECK (age >= 0),
    color        VARCHAR(50),
    weight       NUMERIC(10,2),
    quantity     INTEGER NOT NULL DEFAULT 0,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
