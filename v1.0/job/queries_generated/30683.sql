WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ai.title AS movie_title,
        ai.production_year,
        1 AS level
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title ai ON c.movie_id = ai.movie_id
    WHERE 
        ai.production_year IS NOT NULL

    UNION ALL

    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ai.title AS movie_title,
        ai.production_year,
        ah.level + 1
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info c ON ah.actor_id = c.person_id
    JOIN 
        aka_title ai ON c.movie_id = ai.movie_id
    WHERE 
        ai.production_year = ah.production_year + 1
)

SELECT 
    a.actor_name,
    COUNT(DISTINCT ah.movie_title) AS movie_count,
    STRING_AGG(DISTINCT ah.movie_title, ', ') AS movie_titles,
    MAX(ah.production_year) AS last_year_active,
    AVG(ah.level) AS average_level
FROM 
    actor_hierarchy ah
JOIN 
    aka_name a ON ah.actor_id = a.id
GROUP BY 
    a.actor_name
HAVING 
    COUNT(DISTINCT ah.movie_title) > 5 
ORDER BY 
    average_level DESC
LIMIT 10;

-- Additional performance benchmarking metrics
SELECT 
    AVG(m.production_year) AS avg_production_year,
    COUNT(DISTINCT c.id) AS unique_cast_count,
    SUM(CASE WHEN c.nr_order IS NULL THEN 1 ELSE 0 END) AS null_nr_order_count
FROM 
    movie_companies mc
LEFT JOIN 
    aka_title m ON mc.movie_id = m.id
LEFT JOIN 
    cast_info c ON m.id = c.movie_id
WHERE 
    mc.note IS NOT NULL 
    AND m.production_year BETWEEN 1990 AND 2020
    AND (m.title ILIKE '%action%' OR m.title ILIKE '%drama%')
GROUP BY 
    mc.company_id
ORDER BY 
    avg_production_year ASC;
