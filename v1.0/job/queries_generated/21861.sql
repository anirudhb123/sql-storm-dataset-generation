WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title mt
        LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL AND
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
movies_with_info AS (
    SELECT 
        r.movie_id,
        r.movie_title,
        r.production_year,
        r.total_cast,
        mi.info AS additional_info
    FROM 
        ranked_movies r
        LEFT JOIN movie_info mi ON r.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards' LIMIT 1)
),
cast_summary AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ca.movie_id) AS roles_count,
        MAX(ca.nr_order) AS highest_role_order
    FROM 
        aka_name a
        LEFT JOIN cast_info ca ON a.person_id = ca.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT ca.movie_id) >= 5
),
top_cast AS (
    SELECT 
        actor_name,
        roles_count,
        highest_role_order,
        RANK() OVER (ORDER BY roles_count DESC) AS actor_rank
    FROM 
        cast_summary
)

SELECT 
    mw.movie_title,
    mw.production_year,
    mw.total_cast,
    mw.additional_info,
    tc.actor_name,
    tc.roles_count
FROM 
    movies_with_info mw
    LEFT JOIN top_cast tc ON mw.total_cast = tc.highest_role_order
WHERE 
    mw.production_year > 2000
    AND (mw.additional_info IS NOT NULL OR tc.roles_count > 10)
ORDER BY 
    mw.production_year DESC, 
    tc.roles_count DESC NULLS LAST;
