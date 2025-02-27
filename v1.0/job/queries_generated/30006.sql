WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming '1' indicates a movie
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(CASE WHEN a.gender = 'F' THEN 1 ELSE 0 END) AS female_actor_ratio,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    mh.title AS linked_movie_title,
    mh.production_year AS linked_movie_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON mc.movie_id = ci.movie_id
JOIN 
    movie_keyword mk ON mk.movie_id = ci.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT OUTER JOIN 
    movie_hierarchy mh ON mh.movie_id = ci.movie_id
WHERE 
    a.name IS NOT NULL 
    AND a.md5sum IS NOT NULL
    AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
GROUP BY 
    a.name, mh.title, mh.production_year
ORDER BY 
    total_movies DESC 
LIMIT 10;

### Explanation:
- The query utilizes a **recursive CTE** `movie_hierarchy` to gather the hierarchy of movies linked together.
- It aggregates the data based on filters, counting total movies per actor and calculating the female actor ratio as a simple example of string expressions and NULL logic.
- It also includes an **outer join** with the `movie_hierarchy` to retain actors even when no linked movies exist.
- Various predicates and expressions are involved, including a condition to filter `company_type` based on criteria.
- The final result is grouped by actor name, linked movie title, and year, ordered by the number of movies in descending order, limited to the top 10 results.
