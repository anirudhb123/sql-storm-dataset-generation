
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id, 
        a.title, 
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3 
)

SELECT 
    akn.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mh.movie_id) AS num_related_movies,
    LISTAGG(DISTINCT kh.keyword, ', ') WITHIN GROUP (ORDER BY kh.keyword) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY akn.name ORDER BY at.production_year DESC) AS row_num
FROM 
    aka_name akn
JOIN 
    cast_info ci ON akn.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kh ON mk.keyword_id = kh.id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
WHERE 
    akn.name IS NOT NULL
    AND (at.production_year IS NOT NULL OR at.note IS NOT NULL)
    AND akn.md5sum IS NOT NULL
GROUP BY 
    akn.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT mh.movie_id) > 0
ORDER BY 
    akn.name, at.production_year DESC
LIMIT 50;
