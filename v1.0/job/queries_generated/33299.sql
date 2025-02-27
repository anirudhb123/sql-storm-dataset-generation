WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    akn.name AS actor_name,
    akn.person_id,
    mt.title AS movie_title,
    mh.production_year,
    mh.level AS movie_level,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') 
             THEN CAST(mi.info AS DECIMAL) 
             ELSE NULL END) AS average_budget,
    SUM(CASE WHEN kw.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count
FROM 
    aka_name akn
JOIN 
    cast_info ci ON akn.person_id = ci.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    movie_info mi ON ci.movie_id = mi.movie_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = ci.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    mh.production_year >= 2000
    AND (mi.info_type_id IS NULL OR mi.info_type_id <> (SELECT id FROM info_type WHERE info = 'trivia'))
GROUP BY 
    akn.name, akn.person_id, mt.title, mh.production_year, mh.level
ORDER BY 
    actor_name, movie_title;

This SQL query is designed to benchmark complex query performance on the Join Order Benchmark schema. It employs various constructs:

1. **Recursive CTE**: To create a hierarchy of movies linked together, grabbing sequential levels of connections from the `movie_link` table.
2. **Aggregations**: Using `COUNT`, `STRING_AGG`, and `AVG` to derive metrics such as the count of companies, names, and average budget from `movie_info`.
3. **Outer Joins**: To fetch information from `movie_keyword` and `company_name`, ensuring that results are not limited by missing entries in these tables.
4. **Subqueries**: Specifically, to filter movies based on specific criteria using subselects in the `WHERE` clause.
5. **Complex CASE expressions**: To compute conditional averages for budgets based on info types.
6. **NULL Logic**: Handling possible NULL values in the joins and aggregations.

In this way, the query demonstrates multiple SQL constructs while addressing real-world data combinations in the movie dataset.
