WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT cc.id) AS co_actors_count,
    STRING_AGG(DISTINCT ak2.name, ', ') AS co_actors_list,
    ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY COUNT(cc.id) DESC) AS ranking,
    CASE 
        WHEN at.production_year < 2010 THEN 'Classic'
        WHEN at.production_year BETWEEN 2010 AND 2019 THEN 'Modern'
        ELSE 'Recent'
    END AS era_classification
FROM 
    cast_info ci
INNER JOIN 
    aka_name ak ON ci.person_id = ak.person_id
INNER JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak2 ON cc.subject_id = ak2.person_id
WHERE 
    at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    AND ak.name IS NOT NULL
    AND ak2.name IS NOT NULL
GROUP BY 
    ak.name, at.id, at.title, at.production_year
HAVING 
    COUNT(DISTINCT cc.id) > 2
ORDER BY 
    ranking, movie_title;

-- Additional performance metrics
EXPLAIN ANALYZE
SELECT 
    movie_id, 
    COUNT(*) AS actor_count
FROM 
    cast_info
GROUP BY 
    movie_id
HAVING 
    COUNT(*) > 5
ORDER BY 
    actor_count DESC
LIMIT 10;

This query accomplishes several complex tasks:
1. It uses a recursive Common Table Expression (CTE) to traverse movie links and establish a hierarchy of movies produced from the year 2000 onwards.
2. The main SELECT statement gathers actor names, movie titles, and production years, along with a count and list of co-actors.
3. It employs conditional logic to categorize movies by era based on their production year.
4. An EXPLAIN ANALYZE is included at the end to benchmark the performance of a query counting the number of actors per movie, filtering those with more than five actors, and sorting the results.
5. It showcases various SQL constructs including aggregates, JOINs (both INNER and LEFT), subqueries, and window functions.
