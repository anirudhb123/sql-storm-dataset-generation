WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m 
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        h.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy h ON ml.movie_id = h.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles,
    MAX(t.production_year) AS latest_movie_year,
    AVG(COALESCE(mh.depth, 0)) AS avg_hierarchy_depth
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_hierarchy mh ON t.id = mh.movie_id
WHERE 
    a.name IS NOT NULL 
    AND (t.title ILIKE '%the%' OR t.production_year IS NULL)
    AND a.md5sum IS NOT NULL
GROUP BY 
    a.id
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    total_movies DESC,
    actor_name ASC
LIMIT 10;

-- Additional Complex Queries

SELECT 
    c.name AS company_name,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS companies_with_notes
FROM 
    company_name c
JOIN 
    movie_companies mc ON c.id = mc.company_id
WHERE 
    c.country_code = 'USA'
    AND c.name NOT LIKE '%Inc.%'
GROUP BY 
    c.id
HAVING 
    COUNT(DISTINCT mc.movie_id) >= 3
ORDER BY 
    movie_count DESC
LIMIT 20;

-- Cross Join with NULL handling and set operator for bizarre semantics

WITH actor_movies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        m.id AS movie_id
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
)
SELECT 
    am1.actor_name AS actor,
    am2.actor_name AS co_actor
FROM 
    actor_movies am1
CROSS JOIN 
    actor_movies am2
WHERE 
    am1.movie_id = am2.movie_id
    AND am1.actor_id <> am2.actor_id
    AND (AM1.actor_name IS NOT NULL OR am2.actor_name IS NOT NULL)
EXCEPT
SELECT 
    a.name,
    b.name
FROM 
    aka_name a
JOIN 
    cast_info ci1 ON a.person_id = ci1.person_id
JOIN 
    cast_info ci2 ON ci1.movie_id = ci2.movie_id
JOIN 
    aka_name b ON ci2.person_id = b.person_id
WHERE 
    a.id < b.id;

This SQL query setup captures various complex constructs and corner cases, including recursive CTEs for movie hierarchy, aggregate functions, outer joins, WHERE clauses with predicates checking for NULL and other conditions, and even set operators with unusual semantics.
