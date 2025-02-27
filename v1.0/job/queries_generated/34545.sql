WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS title, 
        m.production_year AS year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL 

    SELECT 
        ml.linked_movie_id AS movie_id, 
        a.title AS title, 
        a.production_year AS year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    name.name AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS total_movies,
    AVG(mh.depth) AS avg_link_depth,
    STRING_AGG(DISTINCT a.title, ', ') AS all_linked_titles,
    ARRAY_AGG(DISTINCT h.name ORDER BY h.name) AS unique_other_actors
FROM 
    cast_info AS c
JOIN 
    aka_name AS name ON c.person_id = name.person_id
LEFT JOIN 
    MovieHierarchy AS mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies AS mc ON c.movie_id = mc.movie_id
LEFT JOIN 
    company_name AS cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword AS mk ON c.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
JOIN 
    (SELECT 
        mh.depth, 
        c2.person_id, 
        mh.movie_id
     FROM 
        cast_info c2
     JOIN 
        MovieHierarchy mh ON c2.movie_id = mh.movie_id
    ) AS h ON h.movie_id = c.movie_id AND h.person_id != c.person_id
WHERE 
    name.name IS NOT NULL 
    AND (cn.country_code IS NULL OR cn.country_code = 'USA')
GROUP BY 
    name.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 10
ORDER BY 
    total_movies DESC;
