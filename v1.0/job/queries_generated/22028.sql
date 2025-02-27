WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1,
        CAST(mh.path || ' -> ' || mt.title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COUNT(DISTINCT actor.id) OVER (PARTITION BY ak.name) AS movie_count,
    mh.level,
    mh.path,
    STRING_AGG(DISTINCT mt.keyword || ' (' || COUNT(mo.id) || ')', ', ' ORDER BY COUNT(mo.id) DESC) AS keyword_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword mt ON mk.keyword_id = mt.id
LEFT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
LEFT JOIN 
    movie_info mo ON at.id = mo.movie_id AND mo.info IS NOT NULL
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND (ak.md5sum IS NULL OR ak.md5sum != '')
    AND (at.production_year BETWEEN 2000 AND 2023 OR mh.level IS NOT NULL)
GROUP BY 
    ak.name, at.title, mh.level, mh.path
HAVING 
    COUNT(DISTINCT mk.id) > 0
ORDER BY 
    movie_count DESC, ak.name;


### Explanation:
1. **CTE with Recursion**: The `movie_hierarchy` CTE establishes a recursive relationship to gather movies that link to one another, limiting the recursive depth to a maximum of 5 levels to avoid excessive recursion.
  
2. **JOINs**: The main query involves various joins across multiple tables: `aka_name`, `cast_info`, `aka_title`, `movie_keyword`, `keyword`, and the `movie_hierarchy` CTE itself.

3. **Window Functions**: Utilizing `COUNT(DISTINCT actor.id) OVER (PARTITION BY ak.name)` allows for performance benchmarking by counting unique movies where each actor has played a role.

4. **String Aggregation**: Using `STRING_AGG` to concatenate keyword information provides a detailed view of how many times each keyword is associated with movies.

5. **NULL Logic and Conditions**: The `WHERE` clause involves multiple conditions to handle potential NULLs and empty values, illustrating robustness in handling bad data.

6. **Complicated HAVING**: The HAVING clause ensures that only those actors associated with at least one keyword are returned.

7. **Bizarre Corner Cases**: The use of `vh.level` > 0 along with other unconventional predicates showcases intricate querying methods against the dataset.

This query showcases a complex SQL structure, employing various SQL features necessary for performance testing and data extraction.
