
WITH RECURSIVE film_series AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS series_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
    AND t.kind_id IN (
        SELECT k.id FROM kind_type k WHERE k.kind ILIKE '%series%'
    )
),
cast_aggregates AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(CASE WHEN r.role = 'lead' THEN 1 ELSE 0 END) AS has_lead_role,
        AVG(CASE WHEN r.role IS NOT NULL THEN r.id ELSE NULL END) AS avg_role_rank
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.movie_id
),
company_movies AS (
    SELECT 
        mc.movie_id,
        COALESCE(cn.country_code, 'Unknown') AS country,
        COUNT(mc.id) AS companies_involved
    FROM movie_companies mc
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id, cn.country_code
),
movie_info_text AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS combined_info
    FROM movie_info mi
    WHERE mi.note IS NULL OR mi.note != 'discard'
    GROUP BY mi.movie_id
)
SELECT 
    f.title_id,
    f.title,
    f.production_year,
    f.series_rank,
    ca.total_cast,
    ca.has_lead_role,
    ca.avg_role_rank,
    cm.country,
    cm.companies_involved,
    COALESCE(mit.combined_info, 'No info available') AS additional_info
FROM film_series f
LEFT JOIN cast_aggregates ca ON f.title_id = ca.movie_id
LEFT JOIN company_movies cm ON f.title_id = cm.movie_id
LEFT JOIN movie_info_text mit ON f.title_id = mit.movie_id
WHERE
    (ca.total_cast IS NULL OR ca.total_cast > 0) 
    AND (cm.companies_involved IS NOT NULL AND cm.companies_involved > 0)
ORDER BY f.production_year DESC, f.series_rank ASC
LIMIT 100;
