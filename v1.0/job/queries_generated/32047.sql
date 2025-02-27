WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1 AS depth
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY mh.production_year DESC) AS rn
    FROM 
        MovieHierarchy mh
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    STRING_AGG(DISTINCT cn.name, ', ') AS production_companies,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    COUNT(DISTINCT CAST(c.role_id AS VARCHAR)) AS roles_count
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title mt ON c.movie_id = mt.movie_id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    mt.production_year BETWEEN 2000 AND 2023
    AND ak.name IS NOT NULL
    AND c.note IS NULL
    AND mt.id IN (SELECT movie_id FROM TopMovies WHERE rn <= 5)
GROUP BY 
    ak.name, mt.title, mt.production_year
ORDER BY 
    mt.production_year DESC, ak.name;
