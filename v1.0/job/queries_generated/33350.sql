WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mv.id AS movie_id,
        mv.title,
        mv.production_year,
        1 AS level
    FROM 
        aka_title AS mv
    WHERE 
        mv.production_year >= 2000

    UNION ALL

    SELECT 
        l.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link AS l
    JOIN 
        aka_title AS a ON l.movie_id = a.id
    JOIN 
        movie_hierarchy AS mh ON l.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT ci.id) AS total_roles,
    AVG(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE ci.nr_order END) AS avg_order,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY m.production_year DESC) AS movie_rank
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    aka_title AS m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword AS mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy AS mh ON m.id = mh.movie_id
WHERE 
    a.name IS NOT NULL 
    AND m.production_year > 2010
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT k.id) > 2 
    AND MAX(ci.nr_order) > 1
ORDER BY 
    actor_name, movie_rank;

