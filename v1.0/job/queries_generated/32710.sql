WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    AVG(mi.info_length) AS avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         LENGTH(info) AS info_length 
     FROM 
         movie_info 
     WHERE 
         info_type_id IN (SELECT id FROM info_type WHERE info = 'plot')
    ) mi ON mi.movie_id = mh.movie_id
WHERE 
    mh.level <= 2
GROUP BY 
    mh.title, mh.production_year, k.keyword
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
    AND COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    mh.production_year DESC, 
    total_cast DESC;

This SQL query performs the following functions:

1. **Recursive CTE** (`movie_hierarchy`): It generates a hierarchy of movies, including linked movies, to allow for deeper insights when analyzing movie relationships.

2. **Joins**: It leverages various outer and inner joins to connect relevant tables, including `movie_keyword`, `complete_cast`, `cast_info`, and `movie_companies`, to gather a comprehensive view of the movies.

3. **Window Function**: It utilizes `ROW_NUMBER()` to rank the results based on the total cast per production year.

4. **Aggregations**: It calculates counts of distinct cast and companies, as well as averages of info lengths related to movie plots.

5. **Filtering**: The `HAVING` clause ensures that only movies with casts and companies are selected for the final output.

6. **Complicated Predicates**: Utilizes `WHERE` conditions to apply filtering based on movie levels and to ensure relevant info from the `movie_info` table.

The result provides a detailed view of movies alongside their trends, cast involvement, and associated keywords while enforcing a structured output.
