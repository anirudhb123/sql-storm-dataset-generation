WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
)

SELECT 
    a.name AS actor_name,
    coalesce(k.keyword, 'No Keywords') AS keyword,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.id) AS cast_count,
    SUM(CASE WHEN mi.info LIKE '%Oscar%' THEN 1 ELSE 0 END) AS oscar_movies,
    ROW_NUMBER() OVER(PARTITION BY a.name ORDER BY mh.production_year DESC) AS movie_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Awards'
    )
GROUP BY 
    a.name, k.keyword, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.id) > 2 
    AND SUM(CASE WHEN mi.info LIKE '%Oscar%' THEN 1 ELSE 0 END) > 0
ORDER BY 
    a.name, mh.production_year;
