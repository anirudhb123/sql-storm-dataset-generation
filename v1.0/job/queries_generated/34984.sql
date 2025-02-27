WITH RECURSIVE MovieHierarchy AS (
    -- Recursive CTE to find the hierarchy of movies
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mn.title,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title mn ON ml.linked_movie_id = mn.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    ac.role_id,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank_by_company_count,
    STRING_AGG(DISTINCT mn.keyword, ', ') FILTER (WHERE mn.keyword IS NOT NULL) AS keywords
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword mn ON mk.keyword_id = mn.id
WHERE 
    ak.name IS NOT NULL
    AND mt.production_year IS NOT NULL
    AND ci.nr_order < 5
    AND (mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') OR mt.kind_id IS NULL)
GROUP BY 
    ak.name, ac.role_id, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    rank_by_company_count, mt.production_year DESC;

This SQL query constructs a recursive Common Table Expression (CTE) to retrieve a hierarchy of movies produced after the year 2000. The main query aggregates data by joining multiple tables and includes window functions for ranking based on the number of companies associated with each movie. It uses string aggregation to list keywords while filtering out any NULL values. Additionally, complex predicates ensure that the data is accurately filtered to meet specific criteria.
