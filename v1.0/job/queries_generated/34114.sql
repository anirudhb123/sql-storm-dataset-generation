WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    AVG(ti.rating) AS average_rating,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mh.production_year DESC) AS rk
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title at ON mh.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id 
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN (
    SELECT 
        movie_id,
        AVG(CAST(info AS FLOAT)) AS rating
    FROM 
        movie_info
    WHERE 
        info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    GROUP BY 
        movie_id
) ti ON ti.movie_id = at.id
WHERE 
    at.production_year IS NOT NULL
GROUP BY 
    ak.name, at.title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    mh.production_year DESC, ak.name;
