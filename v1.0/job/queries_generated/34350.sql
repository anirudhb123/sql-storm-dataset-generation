WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year = 2023

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5 -- Limit depth to avoid excessive recursion
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    EXTRACT(YEAR FROM CURRENT_DATE) - t.production_year AS movie_age,
    kc.keyword AS movie_keyword,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS movie_rank,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
JOIN 
    movie_hierarchy mh ON mh.movie_id = ci.movie_id
JOIN 
    aka_title t ON ci.movie_id = t.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, kc.keyword
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
    AND movie_age < 10
ORDER BY 
    movie_age ASC, movie_rank DESC
LIMIT 50;

This query performs the following operations:
1. It creates a recursive Common Table Expression (CTE) titled `movie_hierarchy` to gather all linked movies within a maximum depth of 5 that were produced in the year 2023.
2. It selects various fields such as actor names, movie titles, the age of the movies, and associated keywords while joining several tables including `cast_info`, `aka_name`, `movie_companies`, `movie_keyword`, and `aka_title`.
3. It uses window functions, specifically `ROW_NUMBER()`, to rank movies for each actor based on production year.
4. The `HAVING` clause filters results to only show actors with movies produced within the last ten years and having collaborated with more than one movie company.
5. The final output is sorted by movie age and actor rank, with a limit of 50 results.
