WITH RECURSIVE movie_chain AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        (SELECT COUNT(*)
         FROM cast_info ci
         WHERE ci.movie_id = m.id
         AND ci.role_id IS NOT NULL) AS actor_count,
        COALESCE((SELECT GROUP_CONCAT(DISTINCT c.name ORDER BY c.name)
                   FROM company_name c
                   JOIN movie_companies mc ON mc.company_id = c.id
                   WHERE mc.movie_id = m.id), 'No Companies') AS associated_companies,
        m.production_year
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        t.title,
        (SELECT COUNT(*)
         FROM cast_info ci
         WHERE ci.movie_id = ml.linked_movie_id
         AND ci.role_id IS NOT NULL) AS actor_count,
        COALESCE((SELECT GROUP_CONCAT(DISTINCT c.name ORDER BY c.name)
                   FROM company_name c
                   JOIN movie_companies mc ON mc.company_id = c.id
                   WHERE mc.movie_id = ml.linked_movie_id), 'No Companies') AS associated_companies,
        t.production_year
    FROM 
        movie_link ml
    JOIN 
        aka_title t ON t.id = ml.movie_id
    WHERE 
        t.production_year >= 2000
        AND ml.linked_movie_id IS NOT NULL
),
ranked_movies AS (
    SELECT 
        mc.movie_id,
        mc.title,
        mc.actor_count,
        mc.associated_companies,
        mc.production_year,
        ROW_NUMBER() OVER (PARTITION BY mc.production_year ORDER BY mc.actor_count DESC, mc.title) AS rank
    FROM 
        movie_chain mc
)
SELECT 
    rm.title,
    rm.actor_count,
    rm.associated_companies,
    rm.production_year,
    CASE 
        WHEN rm.actor_count IS NULL THEN 'No actors'
        WHEN rm.actor_count = 0 THEN 'No actors'
        ELSE 'Has actors'
    END AS actor_status
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC;
