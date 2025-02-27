WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        title m
    WHERE 
        m.id IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT cc.movie_id) AS total_movies,
    MAX(mh.level) AS hierarchy_level,
    AVG(CASE 
        WHEN mi.info IS NULL THEN 0 
        ELSE LENGTH(mi.info) 
    END) AS avg_info_length,
    String_agg(DISTINCT c.name, ', ') AS company_names,
    RANK() OVER (PARTITION BY a.name ORDER BY COUNT(cc.movie_id) DESC) AS rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = t.id
WHERE 
    t.production_year IS NOT NULL
    AND (k.keyword IS NOT NULL OR k.keyword IS NULL) -- Example of NULL logic
GROUP BY 
    a.name, t.title, k.keyword
HAVING 
    COUNT(DISTINCT cc.movie_id) > 2
ORDER BY 
    rank, a.name;

This query uses a recursive CTE to build a movie hierarchy based on linked movies. It gathers detailed information regarding actors (aka_name), movies (title), keywords (movie_keyword), and companies (movie_companies). It employs various JOINs, aggregates, window functions, and includes both outer joins and NULL logic. Results are grouped and filtered to show only actors with more than two distinct movies.
