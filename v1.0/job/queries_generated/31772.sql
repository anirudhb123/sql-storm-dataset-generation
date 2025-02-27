WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        CAST(1 AS INTEGER) AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY mh.level DESC) AS hierarchy_level,
    COUNT(DISTINCT kc.keyword) AS keyword_count
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title at ON c.movie_id = at.id
JOIN 
    movie_keyword mk ON at.id = mk.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND mh.production_year IS NOT NULL
GROUP BY 
    ak.id, ak.name, at.id, at.title, mh.production_year
HAVING 
    COUNT(DISTINCT kc.keyword) > 0
ORDER BY 
    actor_name, hierarchy_level DESC, movie_title;

This SQL query performs the following tasks:

1. **Recursive CTE (Common Table Expression)** called `movie_hierarchy` to create a hierarchy of movies linked by `movie_link` starting from movies produced after the year 2000.
   
2. **Joins** the `aka_name`, `cast_info`, `title`, `movie_keyword`, and `keyword` tables to gather data on actors and movies along with their associated keywords.

3. **Window Function** `ROW_NUMBER()` is used to assign a unique level number to each actor’s movies based on their hierarchical depth in the movie linkage.

4. **Aggregate Function** `COUNT(DISTINCT kc.keyword)` counts unique keywords associated with each movie, filtering out entries without keywords.

5. **Conditional Logic** in the `WHERE` clause ensures that we only include movies and actors with valid values.

6. **Group By** helps to consolidate results by actor and movie with keyword counts.

7. **Order By** sorts the final output by actor name, descending hierarchy level and movie title for clarity in viewing the results.
