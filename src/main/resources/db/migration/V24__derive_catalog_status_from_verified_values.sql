-- V24: derive catalog-level trust from current, field-level verification snapshots.
-- Legacy events with NULL verified_values remain auditable but cannot prove current values.
-- Price verification remains independent and is intentionally excluded from essential-field status.

DROP TRIGGER IF EXISTS trg_sync_attraction_verification_status
    ON attraction_verification_history;
DROP TRIGGER IF EXISTS trg_sync_activity_verification_status
    ON activity_verification_history;

DROP FUNCTION IF EXISTS sync_attraction_verification_status();
DROP FUNCTION IF EXISTS sync_activity_verification_status();

CREATE OR REPLACE FUNCTION recalculate_attraction_catalog_status(p_attraction_id BIGINT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_item attractions%ROWTYPE;
    v_latest_rejection_id BIGINT;
    v_name_ok BOOLEAN;
    v_description_ok BOOLEAN;
    v_category_ok BOOLEAN;
    v_latitude_ok BOOLEAN;
    v_longitude_ok BOOLEAN;
    v_duration_ok BOOLEAN;
    v_verified_count INTEGER;
    v_new_status VARCHAR(30);
    v_last_verified_at TIMESTAMPTZ;
BEGIN
    SELECT *
      INTO v_item
      FROM attractions
     WHERE id = p_attraction_id;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    SELECT MAX(id)
      INTO v_latest_rejection_id
      FROM attraction_verification_history
     WHERE attraction_id = p_attraction_id
       AND verification_status = 'REJECTED';

    SELECT
        (length(btrim(v_item.name)) > 0 AND EXISTS (
            SELECT 1 FROM attraction_verification_history h
             WHERE h.attraction_id = p_attraction_id
               AND h.id > COALESCE(v_latest_rejection_id, 0)
               AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
               AND h.verified_fields @> ARRAY['name']::TEXT[]
               AND h.verified_values ? 'name'
               AND h.verified_values -> 'name' = to_jsonb(v_item.name)
        )),
        (v_item.description IS NOT NULL AND length(btrim(v_item.description)) > 0 AND EXISTS (
            SELECT 1 FROM attraction_verification_history h
             WHERE h.attraction_id = p_attraction_id
               AND h.id > COALESCE(v_latest_rejection_id, 0)
               AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
               AND h.verified_fields @> ARRAY['description']::TEXT[]
               AND h.verified_values ? 'description'
               AND h.verified_values -> 'description' = to_jsonb(v_item.description)
        )),
        (length(btrim(v_item.category)) > 0 AND EXISTS (
            SELECT 1 FROM attraction_verification_history h
             WHERE h.attraction_id = p_attraction_id
               AND h.id > COALESCE(v_latest_rejection_id, 0)
               AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
               AND h.verified_fields @> ARRAY['category']::TEXT[]
               AND h.verified_values ? 'category'
               AND h.verified_values -> 'category' = to_jsonb(v_item.category)
        )),
        (v_item.latitude IS NOT NULL AND EXISTS (
            SELECT 1 FROM attraction_verification_history h
             WHERE h.attraction_id = p_attraction_id
               AND h.id > COALESCE(v_latest_rejection_id, 0)
               AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
               AND h.verified_fields @> ARRAY['latitude']::TEXT[]
               AND h.verified_values ? 'latitude'
               AND h.verified_values -> 'latitude' = to_jsonb(v_item.latitude)
        )),
        (v_item.longitude IS NOT NULL AND EXISTS (
            SELECT 1 FROM attraction_verification_history h
             WHERE h.attraction_id = p_attraction_id
               AND h.id > COALESCE(v_latest_rejection_id, 0)
               AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
               AND h.verified_fields @> ARRAY['longitude']::TEXT[]
               AND h.verified_values ? 'longitude'
               AND h.verified_values -> 'longitude' = to_jsonb(v_item.longitude)
        )),
        (v_item.estimated_duration_minutes IS NOT NULL
            AND v_item.estimated_duration_minutes > 0 AND EXISTS (
            SELECT 1 FROM attraction_verification_history h
             WHERE h.attraction_id = p_attraction_id
               AND h.id > COALESCE(v_latest_rejection_id, 0)
               AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
               AND h.verified_fields @> ARRAY['estimated_duration_minutes']::TEXT[]
               AND h.verified_values ? 'estimated_duration_minutes'
               AND h.verified_values -> 'estimated_duration_minutes'
                    = to_jsonb(v_item.estimated_duration_minutes)
        ))
    INTO v_name_ok, v_description_ok, v_category_ok,
         v_latitude_ok, v_longitude_ok, v_duration_ok;

    v_verified_count :=
        (CASE WHEN v_name_ok THEN 1 ELSE 0 END) +
        (CASE WHEN v_description_ok THEN 1 ELSE 0 END) +
        (CASE WHEN v_category_ok THEN 1 ELSE 0 END) +
        (CASE WHEN v_latitude_ok THEN 1 ELSE 0 END) +
        (CASE WHEN v_longitude_ok THEN 1 ELSE 0 END) +
        (CASE WHEN v_duration_ok THEN 1 ELSE 0 END);

    IF v_latest_rejection_id IS NOT NULL AND v_verified_count < 6 THEN
        v_new_status := 'REJECTED';
    ELSIF v_verified_count = 6 THEN
        v_new_status := 'VERIFIED';
    ELSIF v_verified_count > 0 THEN
        v_new_status := 'PARTIALLY_VERIFIED';
    ELSE
        v_new_status := 'UNVERIFIED';
    END IF;

    IF v_new_status = 'VERIFIED' THEN
        SELECT MAX(h.verified_at)
          INTO v_last_verified_at
          FROM attraction_verification_history h
         WHERE h.attraction_id = p_attraction_id
           AND h.id > COALESCE(v_latest_rejection_id, 0)
           AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                      AND (
                (h.verified_fields @> ARRAY['name']::TEXT[]
                    AND h.verified_values ? 'name'
                    AND h.verified_values -> 'name' = to_jsonb(v_item.name))
                OR (h.verified_fields @> ARRAY['description']::TEXT[]
                    AND h.verified_values ? 'description'
                    AND h.verified_values -> 'description' = to_jsonb(v_item.description))
                OR (h.verified_fields @> ARRAY['category']::TEXT[]
                    AND h.verified_values ? 'category'
                    AND h.verified_values -> 'category' = to_jsonb(v_item.category))
                OR (h.verified_fields @> ARRAY['latitude']::TEXT[]
                    AND h.verified_values ? 'latitude'
                    AND h.verified_values -> 'latitude' = to_jsonb(v_item.latitude))
                OR (h.verified_fields @> ARRAY['longitude']::TEXT[]
                    AND h.verified_values ? 'longitude'
                    AND h.verified_values -> 'longitude' = to_jsonb(v_item.longitude))
                OR (h.verified_fields @> ARRAY['estimated_duration_minutes']::TEXT[]
                    AND h.verified_values ? 'estimated_duration_minutes'
                    AND h.verified_values -> 'estimated_duration_minutes'
                        = to_jsonb(v_item.estimated_duration_minutes))
            );
    ELSE
        v_last_verified_at := NULL;
    END IF;

    UPDATE attractions
       SET data_status = v_new_status,
           last_verified_at = v_last_verified_at
     WHERE id = p_attraction_id
       AND (data_status IS DISTINCT FROM v_new_status
            OR last_verified_at IS DISTINCT FROM v_last_verified_at);
END;
$$;

CREATE OR REPLACE FUNCTION recalculate_activity_catalog_status(p_activity_id BIGINT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_item activities%ROWTYPE;
    v_latest_rejection_id BIGINT;
    v_name_ok BOOLEAN;
    v_description_ok BOOLEAN;
    v_category_ok BOOLEAN;
    v_latitude_ok BOOLEAN;
    v_longitude_ok BOOLEAN;
    v_duration_ok BOOLEAN;
    v_verified_count INTEGER;
    v_new_status VARCHAR(30);
    v_last_verified_at TIMESTAMPTZ;
BEGIN
    SELECT *
      INTO v_item
      FROM activities
     WHERE id = p_activity_id;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    SELECT MAX(id)
      INTO v_latest_rejection_id
      FROM activity_verification_history
     WHERE activity_id = p_activity_id
       AND verification_status = 'REJECTED';

    SELECT
        (length(btrim(v_item.name)) > 0 AND EXISTS (
            SELECT 1 FROM activity_verification_history h
             WHERE h.activity_id = p_activity_id
               AND h.id > COALESCE(v_latest_rejection_id, 0)
               AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
               AND h.verified_fields @> ARRAY['name']::TEXT[]
               AND h.verified_values ? 'name'
               AND h.verified_values -> 'name' = to_jsonb(v_item.name)
        )),
        (v_item.description IS NOT NULL AND length(btrim(v_item.description)) > 0 AND EXISTS (
            SELECT 1 FROM activity_verification_history h
             WHERE h.activity_id = p_activity_id
               AND h.id > COALESCE(v_latest_rejection_id, 0)
               AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
               AND h.verified_fields @> ARRAY['description']::TEXT[]
               AND h.verified_values ? 'description'
               AND h.verified_values -> 'description' = to_jsonb(v_item.description)
        )),
        (length(btrim(v_item.category)) > 0 AND EXISTS (
            SELECT 1 FROM activity_verification_history h
             WHERE h.activity_id = p_activity_id
               AND h.id > COALESCE(v_latest_rejection_id, 0)
               AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
               AND h.verified_fields @> ARRAY['category']::TEXT[]
               AND h.verified_values ? 'category'
               AND h.verified_values -> 'category' = to_jsonb(v_item.category)
        )),
        (v_item.latitude IS NOT NULL AND EXISTS (
            SELECT 1 FROM activity_verification_history h
             WHERE h.activity_id = p_activity_id
               AND h.id > COALESCE(v_latest_rejection_id, 0)
               AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
               AND h.verified_fields @> ARRAY['latitude']::TEXT[]
               AND h.verified_values ? 'latitude'
               AND h.verified_values -> 'latitude' = to_jsonb(v_item.latitude)
        )),
        (v_item.longitude IS NOT NULL AND EXISTS (
            SELECT 1 FROM activity_verification_history h
             WHERE h.activity_id = p_activity_id
               AND h.id > COALESCE(v_latest_rejection_id, 0)
               AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
               AND h.verified_fields @> ARRAY['longitude']::TEXT[]
               AND h.verified_values ? 'longitude'
               AND h.verified_values -> 'longitude' = to_jsonb(v_item.longitude)
        )),
        (v_item.estimated_duration_minutes IS NOT NULL
            AND v_item.estimated_duration_minutes > 0 AND EXISTS (
            SELECT 1 FROM activity_verification_history h
             WHERE h.activity_id = p_activity_id
               AND h.id > COALESCE(v_latest_rejection_id, 0)
               AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
               AND h.verified_fields @> ARRAY['estimated_duration_minutes']::TEXT[]
               AND h.verified_values ? 'estimated_duration_minutes'
               AND h.verified_values -> 'estimated_duration_minutes'
                    = to_jsonb(v_item.estimated_duration_minutes)
        ))
    INTO v_name_ok, v_description_ok, v_category_ok,
         v_latitude_ok, v_longitude_ok, v_duration_ok;

    v_verified_count :=
        (CASE WHEN v_name_ok THEN 1 ELSE 0 END) +
        (CASE WHEN v_description_ok THEN 1 ELSE 0 END) +
        (CASE WHEN v_category_ok THEN 1 ELSE 0 END) +
        (CASE WHEN v_latitude_ok THEN 1 ELSE 0 END) +
        (CASE WHEN v_longitude_ok THEN 1 ELSE 0 END) +
        (CASE WHEN v_duration_ok THEN 1 ELSE 0 END);

    IF v_latest_rejection_id IS NOT NULL AND v_verified_count < 6 THEN
        v_new_status := 'REJECTED';
    ELSIF v_verified_count = 6 THEN
        v_new_status := 'VERIFIED';
    ELSIF v_verified_count > 0 THEN
        v_new_status := 'PARTIALLY_VERIFIED';
    ELSE
        v_new_status := 'UNVERIFIED';
    END IF;

    IF v_new_status = 'VERIFIED' THEN
        SELECT MAX(h.verified_at)
          INTO v_last_verified_at
          FROM activity_verification_history h
         WHERE h.activity_id = p_activity_id
           AND h.id > COALESCE(v_latest_rejection_id, 0)
           AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                      AND (
                (h.verified_fields @> ARRAY['name']::TEXT[]
                    AND h.verified_values ? 'name'
                    AND h.verified_values -> 'name' = to_jsonb(v_item.name))
                OR (h.verified_fields @> ARRAY['description']::TEXT[]
                    AND h.verified_values ? 'description'
                    AND h.verified_values -> 'description' = to_jsonb(v_item.description))
                OR (h.verified_fields @> ARRAY['category']::TEXT[]
                    AND h.verified_values ? 'category'
                    AND h.verified_values -> 'category' = to_jsonb(v_item.category))
                OR (h.verified_fields @> ARRAY['latitude']::TEXT[]
                    AND h.verified_values ? 'latitude'
                    AND h.verified_values -> 'latitude' = to_jsonb(v_item.latitude))
                OR (h.verified_fields @> ARRAY['longitude']::TEXT[]
                    AND h.verified_values ? 'longitude'
                    AND h.verified_values -> 'longitude' = to_jsonb(v_item.longitude))
                OR (h.verified_fields @> ARRAY['estimated_duration_minutes']::TEXT[]
                    AND h.verified_values ? 'estimated_duration_minutes'
                    AND h.verified_values -> 'estimated_duration_minutes'
                        = to_jsonb(v_item.estimated_duration_minutes))
            );
    ELSE
        v_last_verified_at := NULL;
    END IF;

    UPDATE activities
       SET data_status = v_new_status,
           last_verified_at = v_last_verified_at
     WHERE id = p_activity_id
       AND (data_status IS DISTINCT FROM v_new_status
            OR last_verified_at IS DISTINCT FROM v_last_verified_at);
END;
$$;

CREATE OR REPLACE FUNCTION trg_recalculate_attraction_status_after_verification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM recalculate_attraction_catalog_status(NEW.attraction_id);
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION trg_recalculate_activity_status_after_verification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM recalculate_activity_catalog_status(NEW.activity_id);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_recalculate_attraction_status_after_verification
AFTER INSERT ON attraction_verification_history
FOR EACH ROW
EXECUTE FUNCTION trg_recalculate_attraction_status_after_verification();

CREATE TRIGGER trg_recalculate_activity_status_after_verification
AFTER INSERT ON activity_verification_history
FOR EACH ROW
EXECUTE FUNCTION trg_recalculate_activity_status_after_verification();

CREATE OR REPLACE FUNCTION trg_recalculate_attraction_status_after_catalog_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM recalculate_attraction_catalog_status(NEW.id);
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION trg_recalculate_activity_status_after_catalog_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM recalculate_activity_catalog_status(NEW.id);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_recalculate_attraction_status_after_catalog_change
AFTER UPDATE OF name, description, category, latitude, longitude, estimated_duration_minutes
ON attractions
FOR EACH ROW
WHEN (
    OLD.name IS DISTINCT FROM NEW.name
    OR OLD.description IS DISTINCT FROM NEW.description
    OR OLD.category IS DISTINCT FROM NEW.category
    OR OLD.latitude IS DISTINCT FROM NEW.latitude
    OR OLD.longitude IS DISTINCT FROM NEW.longitude
    OR OLD.estimated_duration_minutes IS DISTINCT FROM NEW.estimated_duration_minutes
)
EXECUTE FUNCTION trg_recalculate_attraction_status_after_catalog_change();

CREATE TRIGGER trg_recalculate_activity_status_after_catalog_change
AFTER UPDATE OF name, description, category, latitude, longitude, estimated_duration_minutes
ON activities
FOR EACH ROW
WHEN (
    OLD.name IS DISTINCT FROM NEW.name
    OR OLD.description IS DISTINCT FROM NEW.description
    OR OLD.category IS DISTINCT FROM NEW.category
    OR OLD.latitude IS DISTINCT FROM NEW.latitude
    OR OLD.longitude IS DISTINCT FROM NEW.longitude
    OR OLD.estimated_duration_minutes IS DISTINCT FROM NEW.estimated_duration_minutes
)
EXECUTE FUNCTION trg_recalculate_activity_status_after_catalog_change();

-- Reconcile existing rows. Legacy verification events have no value snapshots and
-- therefore cannot establish current field-level proof. Historical REJECTED events
-- remain authoritative until all six fields are freshly verified after the rejection.
DO $$
DECLARE
    v_id BIGINT;
BEGIN
    FOR v_id IN SELECT id FROM attractions LOOP
        PERFORM recalculate_attraction_catalog_status(v_id);
    END LOOP;

    FOR v_id IN SELECT id FROM activities LOOP
        PERFORM recalculate_activity_catalog_status(v_id);
    END LOOP;
END;
$$;

COMMENT ON FUNCTION recalculate_attraction_catalog_status(BIGINT) IS
    'Recalculates attraction trust from current-value-matching field snapshots; price evidence is independent.';
COMMENT ON FUNCTION recalculate_activity_catalog_status(BIGINT) IS
    'Recalculates activity trust from current-value-matching field snapshots; price evidence is independent.';
