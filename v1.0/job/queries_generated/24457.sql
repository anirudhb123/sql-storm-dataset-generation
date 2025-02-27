WITH recursive movie_hierarchy AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mc.company_id,
        COUNT(c.id) AS actor_count
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        cast_info c ON mt.id = c.movie_id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
    GROUP BY 
        mt.movie_id, mt.title, mc.company_id
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.company_id,
        mh.actor_count + 1 -- Increment count for each recursive step
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'Sequel')
)
SELECT 
    m.title AS movie_title,
    c.name AS company_name,
    (SELECT COUNT(DISTINCT ai.id) 
     FROM aka_name ai 
     JOIN cast_info ci ON ai.person_id = ci.person_id 
     WHERE ci.movie_id = m.movie_id) AS distinct_actor_count,
    ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY c.name) AS rn,
    COALESCE(SUM(mk.keyword = 'Action') FILTER (WHERE mk.keyword IS NOT NULL), 0) AS action_keyword_count,
    NULLIF(COUNT(DISTINCT mi.info), 0) AS non_null_info_count,
    NULLIF(MAX(chg.production_year), 2023) AS last_change_year -- Assuming 2023 is the current year for NULL logic
FROM 
    movie_hierarchy m
JOIN 
    company_name c ON m.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    aka_title chg ON m.movie_id = chg.id
WHERE 
    m.actor_count > 0
GROUP BY 
    m.movie_id, m.title, c.name
HAVING 
    COUNT(DISTINCT mk.keyword) > 1 
ORDER BY 
    last_change_year DESC, actor_count DESC
LIMIT 10;

This SQL query performs a performance benchmarking operation on a movie database, leveraging various complex SQL constructs such as a recursive Common Table Expression (CTE), various types of joins (including LEFT JOINs), window functions, set operators, and intricate conditional logic to work with NULL values. It establishes a hierarchy of movies, considers distinct actors, counts specific keywords, and evaluates other metrics while ensuring to handle edge cases gracefully, such as NULL calculations and recursive relationships.
