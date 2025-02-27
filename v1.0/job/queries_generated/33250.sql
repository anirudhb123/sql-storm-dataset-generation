WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3
)

SELECT 
    akn.name AS actor_name,
    att.title AS movie_title,
    att.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(pi.info::float) AS average_rating,
    RANK() OVER (PARTITION BY att.production_year ORDER BY COUNT(mk.keyword) DESC) AS keyword_rank
FROM 
    aka_name akn
JOIN 
    cast_info ci ON akn.person_id = ci.person_id
JOIN 
    aka_title att ON ci.movie_id = att.id
LEFT JOIN 
    movie_keyword mk ON att.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON att.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
LEFT JOIN 
    MovieHierarchy mh ON att.id = mh.movie_id
WHERE 
    att.production_year BETWEEN 2000 AND 2020
    AND akn.name IS NOT NULL
    AND (mi.info IS NULL OR mi.info::float > 5.0)
GROUP BY 
    akn.name, att.title, att.production_year
HAVING 
    COUNT(DISTINCT mk.keyword) > 0
ORDER BY 
    average_rating DESC, keyword_count DESC;
