WITH RECURSIVE movie_hierarchy AS (
    SELECT mt1.movie_id, mt1.title, mt1.production_year, 1 as level
    FROM aka_title mt1
    WHERE mt1.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT mt2.movie_id, mt2.title, mt2.production_year, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt2 ON ml.linked_movie_id = mt2.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(mk.keyword_count) AS total_keywords,
    SUM(mh.level) AS total_hierarchy_levels,
    ROW_NUMBER() OVER(PARTITION BY ak.name ORDER BY at.production_year DESC) AS rn
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN aka_title at ON ci.movie_id = at.id
LEFT JOIN (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
) AS mk ON at.id = mk.movie_id
LEFT JOIN (
    SELECT mc.movie_id, mc.company_id
    FROM movie_companies mc
    GROUP BY mc.movie_id, mc.company_id
) AS mc ON at.id = mc.movie_id
JOIN movie_hierarchy mh ON at.id = mh.movie_id
WHERE ak.name IS NOT NULL
AND ak.name NOT LIKE '%[0-9]%'
AND at.production_year > 2000
GROUP BY ak.name, at.title
HAVING COUNT(DISTINCT mc.company_id) > 0
ORDER BY total_hierarchy_levels DESC, rn
LIMIT 10;


This SQL query:

1. **Recursive CTE**: Builds a hierarchy of movies and their linked counterparts.
2. **Joins**: Combines data from multiple tables including `aka_name`, `cast_info`, `aka_title`, `movie_keyword`, and `movie_companies`.
3. **Aggregate Functions**: Counts distinct companies and total keywords while summing hierarchy levels.
4. **Window Function**: Ranks actors based on movie production year.
5. **Complicated Predicates**: Filters out names ending with numbers, only includes titles from the 21st century, and ensures that the actor has worked on movies with associated companies.
6. **Grouping and Ordering**: Groups results by actor name and movie title and orders by hierarchy levels and production year.

This query showcases several advanced SQL techniques while benchmarking the performance of queries against the specified schema.
