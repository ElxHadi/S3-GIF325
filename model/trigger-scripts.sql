-- DROP FUNCTION public.check_availability(varchar, varchar, timestamp, timestamp);

CREATE OR REPLACE FUNCTION public.check_availability(local_pavillon character varying, local_numero character varying, desired_date_debut timestamp without time zone, desired_date_fin timestamp without time zone)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    overlap_exists BOOLEAN;
BEGIN
    -- Check if there is any reservation that overlaps with the desired period
    SELECT EXISTS (
        SELECT 1
        FROM RESERVER
        WHERE pavillon = local_pavillon
          AND numero = local_numero
          AND date_debut < desired_date_fin
          AND date_fin > desired_date_debut
    ) INTO overlap_exists;

    RETURN NOT overlap_exists;  -- Return true if no overlap exists
END;
$function$
;

-- DROP FUNCTION public.check_dates(timestamp, timestamp);

CREATE OR REPLACE FUNCTION public.check_dates(reservation_start timestamp without time zone, reservation_end timestamp without time zone)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Check if the end date is after the start date and if the duration is less than 24 hours
    RETURN reservation_end > reservation_start AND (reservation_end - reservation_start) < INTERVAL '24 hours';
END;
$function$
;

-- DROP FUNCTION public.check_permission(varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION public.check_permission(user_cip character varying, local_pavillon character varying, local_numero character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    user_statut_id SMALLINT;
    local_categorie_id SMALLINT;
BEGIN
    -- Get the status of the user
    SELECT id_statut INTO user_statut_id
    FROM POSSEDER
    WHERE cip = user_cip;

    -- Get the category of the local
    SELECT id_categorie INTO local_categorie_id
    FROM LOCAL
    WHERE pavillon = local_pavillon AND numero = local_numero;

    -- Check if the user has permission for the category of the local
    RETURN EXISTS (
        SELECT 1
        FROM STATUT_CATEGORIE
        WHERE id_statut = user_statut_id
        AND id_categorie = local_categorie_id
    );
END;
$function$
;
-- DROP FUNCTION public.handle_reservation();

CREATE OR REPLACE FUNCTION public.handle_reservation()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    is_permissible BOOLEAN;
    is_available BOOLEAN;
    dates_check BOOLEAN;
BEGIN
    -- Check if the user has permission
    is_permissible := public.check_permission(NEW.cip, NEW.pavillon, NEW.numero);
    IF NOT is_permissible THEN
        RAISE EXCEPTION 'Permission denied: The user does not have permission to book this local';
    END IF;

    -- Check if the local is available
    is_available := public.check_availability(NEW.pavillon, NEW.numero, NEW.date_debut, NEW.date_fin);
    IF NOT is_available THEN
        RAISE EXCEPTION 'Local is not available: The local is already booked during the proposed dates.';
    END IF;

    -- Check if the dates are valid
    dates_check := public.check_dates(NEW.date_debut, NEW.date_fin);
    IF NOT dates_check THEN
        RAISE EXCEPTION 'Invalid reservation dates: Reservation must be less than 24 hours.';
    END IF;

    RETURN NEW;
END;
$function$
;

create trigger trg_handle_reservation before
insert
    or
update
    on
    public.reserver for each row execute function handle_reservation()