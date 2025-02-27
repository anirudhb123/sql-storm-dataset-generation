WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'short'))
),
actor_statistics AS (
    SELECT 
        ka.person_id,
        COUNT(DISTINCT ka.movie_id) AS movie_count,
        SUM(CASE WHEN ca.nr_order = 1 THEN 1 ELSE 0 END) AS lead_roles,
        AVG(COALESCE(mi.info_id, 0)) AS average_info
    FROM 
        cast_info ca
    JOIN
        aka_name ka ON ca.person_id = ka.person_id
    LEFT JOIN 
        movie_info mi ON ca.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'rating%')
    GROUP BY 
        ka.person_id
),
high_ranking_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(actors.actor_count, 0) AS actor_count,
        COALESCE(actors.lead_roles, 0) AS lead_role_count
    FROM 
        ranked_movies rm
    LEFT JOIN (
        SELECT 
            ca.movie_id,
            COUNT(DISTINCT ca.person_id) AS actor_count,
            SUM(CASE WHEN ca.nr_order = 1 THEN 1 ELSE 0 END) AS lead_roles
        FROM 
            cast_info ca
        GROUP BY 
            ca.movie_id
    ) actors ON rm.movie_id = actors.movie_id
)
SELECT
    hv.movie_id,
    hv.title,
    hv.production_year,
    hv.actor_count,
    hv.lead_role_count,
    COALESCE(actor_stats.movie_count, 0) AS total_movies_by_actor,
    CASE
        WHEN hv.production_year < 2000 THEN 'Vintage'
        WHEN hv.production_year >= 2000 AND hv.production_year <= 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_category
FROM 
    high_ranking_movies hv
LEFT JOIN 
    actor_statistics actor_stats ON hv.movie_id IN (
        SELECT 
            ca.movie_id 
        FROM 
            cast_info ca 
        WHERE 
            ca.person_id IN (SELECT person_id FROM aka_name WHERE name LIKE '%Smith%')
    )
WHERE 
    hv.actor_count > 0
ORDER BY 
    hv.production_year DESC, hv.title ASC
FETCH FIRST 10 ROWS ONLY;
