WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ka.id AS actor_id,
        ka.name AS actor_name,
        1 AS depth
    FROM 
        aka_name ka
    WHERE 
        ka.name IS NOT NULL

    UNION ALL

    SELECT 
        ka.id AS actor_id,
        ka.name AS actor_name,
        ah.depth + 1 AS depth
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info ci ON ci.person_id = ah.actor_id
    JOIN 
        aka_name ka ON ka.person_id = ci.person_id
    WHERE 
        ah.depth < 3  -- limiting depth to avoid extreme recursion
        AND ci.nr_order IS NOT NULL
)

SELECT 
    a.actor_id AS Actor_ID,
    a.actor_name AS Actor_Name,
    COUNT(DISTINCT c.movie_id) AS Movie_Count,
    STRING_AGG(DISTINCT t.title, ', ') AS Titles,
    MAX(t.production_year) AS Last_Produced_Year,
    MIN(t.production_year) AS First_Produced_Year,
    AVG(t.production_year) FILTER (WHERE t.production_year IS NOT NULL) AS Avg_Production_Year,
    SUM(CASE 
            WHEN c.role_id IS NULL THEN 0 
            ELSE 1 
        END) AS Count_Roles
FROM 
    actor_hierarchy a
LEFT JOIN 
    cast_info ci ON ci.person_id = a.actor_id
LEFT JOIN 
    title t ON t.id = ci.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = ci.movie_id
LEFT JOIN 
    company_name co ON co.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = ci.movie_id
GROUP BY 
    a.actor_id, a.actor_name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5 
    AND AVG(t.production_year) > 2000 
    AND COUNT(DISTINCT t.id) > 3
ORDER BY 
    Last_Produced_Year DESC, Count_Roles DESC 
FETCH FIRST 10 ROWS ONLY;

SELECT 
    DISTINCT 
    k.keyword 
FROM 
    movie_keyword mk 
JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    mk.movie_id IN (
        SELECT 
            DISTINCT mc.movie_id 
        FROM 
            movie_companies mc 
        JOIN 
            company_name co ON co.id = mc.company_id
        WHERE 
            co.country_code IS NULL OR LENGTH(co.country_code) > 2
    )
EXCEPT 
SELECT 
    DISTINCT 
    k.keyword 
FROM 
    movie_keyword mk 
JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    mk.movie_id IN (
        SELECT 
            DISTINCT mc.movie_id 
        FROM 
            movie_companies mc 
        JOIN 
            company_name co ON co.id = mc.company_id
        WHERE 
            co.country_code IN ('US', 'GB')
    );

This SQL query utilizes multiple advanced SQL constructs to create a complex performance benchmarking scenario working with the `Join Order Benchmark` schema. The first part with CTEs, aggregates, and conditional logic searches for actors with defined attributes and relationships, while the second part utilizes a combination of set operators (`EXCEPT`) to emphasize contrasting data based on company nationality effects on movie keywords.
