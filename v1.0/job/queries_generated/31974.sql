WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS a ON ml.linked_movie_id = a.id
    JOIN 
        movie_hierarchy AS mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 5  -- limit the depth of the hierarchy
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    COUNT(DISTINCT co.id) AS company_count,
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS awards_count,
    RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT co.id) DESC) AS company_rank
FROM 
    cast_info AS ci
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON ci.movie_id = mc.movie_id
JOIN 
    company_name AS co ON mc.company_id = co.id
JOIN 
    movie_info AS mi ON ci.movie_id = mi.movie_id
JOIN 
    movie_hierarchy AS m ON ci.movie_id = m.movie_id
WHERE 
    ci.note IS NOT NULL AND 
    a.name IS NOT NULL AND
    m.production_year IS NOT NULL
GROUP BY 
    a.name, m.title
HAVING 
    COUNT(DISTINCT co.id) > 1 AND 
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) > 0
ORDER BY 
    m.production_year, 
    actor_name;

This SQL query performs several tasks:
1. It creates a recursive common table expression (CTE) called `movie_hierarchy` to build a hierarchy of movies linked by their associated movie links while limiting to a maximum depth of 5.
2. It selects actors' names and the titles of movies they acted in, along with the count of distinct companies involved in the production.
3. It calculates the sum of awards for each movie (where `info_type_id = 1` is assumed to represent awards) and ranks them by the number of companies per production year.
4. It uses filtering conditions to exclude NULLs and counts that do not meet the expectations.
5. Finally, it orders the output by production year and actor name, ensuring that only actors involved in movies with more than one production company and at least one award are included in the results.
