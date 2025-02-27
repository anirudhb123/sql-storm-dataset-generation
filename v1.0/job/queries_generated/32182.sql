WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.level + 1 AS level
    FROM 
        movie_link ml 
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.movie_title,
    mt.level,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    ARRAY_AGG(DISTINCT mk.keyword) AS associated_keywords,
    AVG(pi.info::float) AS average_info_per_person
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_hierarchy mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_companies mc ON mt.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    ak.name IS NOT NULL
    AND pi.info_type_id IS NOT NULL
GROUP BY 
    ak.name, mt.movie_title, mt.level
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    mt.level DESC, num_companies DESC, ak.name;

This SQL query involves several advanced features:
1. A recursive Common Table Expression (CTE) `movie_hierarchy` to build a hierarchy of movies linked to each other from the year 2000 onwards.
2. Joining multiple tables such as `cast_info`, `aka_name`, `movie_companies`, `movie_keyword`, and `person_info`.
3. Using aggregate functions like `COUNT`, `ARRAY_AGG`, and `AVG` to compute various statistics related to the movies and their associated actors.
4. Applying filters using `WHERE` and `HAVING` clauses to ensure only relevant results are returned and using NULL checks.
5. Organizing the results through `ORDER BY` with multiple criteria.
