WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY m.production_year DESC) AS rank
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy AS m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_companies AS mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = m.movie_id
WHERE 
    a.name IS NOT NULL
    AND m.production_year IS NOT NULL 
    AND m.level = 1 
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0 
    AND COUNT(DISTINCT mk.keyword_id) > 1
ORDER BY 
    rank, movie_title;