
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1 AS depth,
        CAST(mh.path || ' > ' || at.title AS VARCHAR(255)) AS path
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
    p.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    MAX(mh.path) AS movie_path,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    AVG(years.produced_years) AS average_produced_years
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN (
    SELECT 
        movie_id,
        EXTRACT(YEAR FROM CURRENT_DATE()) - production_year AS produced_years
    FROM 
        aka_title
) years ON years.movie_id = c.movie_id
WHERE 
    p.name IS NOT NULL
GROUP BY 
    p.name, mh.path
ORDER BY 
    movie_count DESC
LIMIT 10;
