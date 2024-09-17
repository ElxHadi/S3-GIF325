-- DROP FUNCTIOM generate_time_slots(TIMESTAMP, TIMESTAMP)
CREATE OR REPLACE FUNCTION generate_time_slots(
    date_debut TIMESTAMP,
    date_fin TIMESTAMP
)
RETURNS TABLE (time_slot TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT generate_series(date_debut, date_fin, '15 minutes'::interval) AS time_slot;
END;
$$ LANGUAGE plpgsql;


/*
SELECT * FROM generate_time_slots(
    '2024-01-01 09:00:00',  -- Début de la période
    '2024-01-01 09:30:00'   -- Fin de la période
);
*/

/*
 * #variable_conflict error
#variable_conflict use_variable
#variable_conflict use_column
 */
--drop function get_local_data(INT);
CREATE OR REPLACE FUNCTION get_local_data(id_categorie INT)
RETURNS TABLE(pavillon VARCHAR, numero VARCHAR) AS $$
#variable_conflict use_variable
BEGIN
    RETURN QUERY
    SELECT l.pavillon, l.numero
    FROM local l
    WHERE l.id_categorie = id_categorie;
END;
$$ LANGUAGE plpgsql;

--select * from get_local_data(1);

--DROP FUNCTION get_reservation_data(start_timestamp TIMESTAMP, end_timestamp TIMESTAMP)
CREATE OR REPLACE FUNCTION get_reservation_data(start_timestamp TIMESTAMP, end_timestamp TIMESTAMP)
RETURNS TABLE(pavillon VARCHAR, numero VARCHAR, date_debut TIMESTAMP, date_fin TIMESTAMP, description VARCHAR) AS $$
#variable_conflict use_variable
BEGIN
    RETURN QUERY
    SELECT r.pavillon, r.numero, r.date_debut, r.date_fin, r.description
    FROM reserver r
    WHERE r.date_debut < end_timestamp
    AND r.date_fin > start_timestamp;
END;
$$ LANGUAGE plpgsql;


--select * from get_reservation_data('2024-10-16 08:00', '2024-10-16 19:00');


CREATE OR REPLACE FUNCTION tableau(
    q_date_debut TIMESTAMP,
    q_date_fin TIMESTAMP,
    q_id_categorie INT
)
RETURNS TABLE(
    pavillon VARCHAR,
    numero VARCHAR,
    time_slot TIMESTAMP,
    description VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    WITH
    time_slots AS (
        SELECT time_slot
        FROM generate_time_slots(q_date_debut, q_date_fin)
    ),
    local_data AS (
        SELECT pavillon, numero
        FROM get_local_data(q_id_categorie)
    ),
    reservation_data AS (
        SELECT pavillon, numero, date_debut, date_fin, description
        FROM get_reservation_data(q_date_debut, q_date_fin)
    )
    SELECT
        l.pavillon,
        l.numero,
        ts.time_slot,
        COALESCE(r.description, NULL) AS description
    FROM time_slots ts
    CROSS JOIN local_data l
    LEFT JOIN reservation_data r
        ON l.pavillon = r.pavillon
        AND l.numero = r.numero
        AND ts.time_slot >= r.date_debut
        AND ts.time_slot < r.date_fin
    ORDER BY l.pavillon, l.numero, ts.time_slot;
END;
$$ LANGUAGE plpgsql;