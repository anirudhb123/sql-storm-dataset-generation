WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        ml.title,
        ml.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles,
    AVG(mh.level) AS avg_movie_level,
    MAX(mh.production_year) AS latest_movie_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    title t ON mh.movie_id = t.id
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 3
ORDER BY 
    movie_count DESC,
    actor_name
LIMIT 10;

-- Combining with a NULL filtering and check for missing links
SELECT 
    co.name AS company_name,
    COUNT(DISTINCT mc.movie_id) AS associated_movies,
    SUM(CASE WHEN mc.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
FROM 
    company_name co
LEFT JOIN 
    movie_companies mc ON co.id = mc.company_id
GROUP BY 
    co.name
HAVING 
    COUNT(DISTINCT mc.movie_id) IS NULL OR COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    associated_movies DESC 
LIMIT 5;

-- Using a complex predicate
SELECT 
    n.name AS character_name,
    COUNT(DISTINCT ci.movie_id) AS total_movies,
    SUM(ci.nr_order) AS total_rank
FROM 
    char_name n
JOIN 
    cast_info ci ON n.id = ci.role_id
WHERE 
    ci.person_role_id IN (SELECT id FROM role_type WHERE role LIKE '%lead%')
    AND ci.nr_order IS NOT NULL
GROUP BY 
    n.name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 2 AND total_rank > 5
ORDER BY 
    total_movies DESC;
