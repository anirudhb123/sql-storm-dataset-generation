
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS title_count
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        COALESCE(rt.role, 'Unknown Role') AS role,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS cast_count
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
),
popular_movies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS unique_cast_count
    FROM 
        aka_title mt
    INNER JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    GROUP BY 
        mt.title, mt.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 10
)
SELECT 
    rt.title,
    rt.production_year,
    rt.title_rank,
    CASE 
        WHEN rt.title_count > 5 THEN 'Multiple Titles'
        ELSE 'Few Titles'
    END AS title_distribution,
    COALESCE(cwr.role, 'No Role') AS actor_role,
    pm.unique_cast_count
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_with_roles cwr ON rt.title_id = cwr.movie_id
LEFT JOIN 
    popular_movies pm ON rt.title = pm.title AND rt.production_year = pm.production_year
WHERE 
    rt.title_rank = 1 OR pm.unique_cast_count IS NOT NULL
ORDER BY 
    rt.production_year DESC, rt.title;
