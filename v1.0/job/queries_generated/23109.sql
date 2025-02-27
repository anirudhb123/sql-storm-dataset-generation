WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(mi.info IS NOT NULL) AS info_exists,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    RANK() OVER(PARTITION BY at.production_year ORDER BY COUNT(mc.company_id) DESC) AS company_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id AND mi.info_type_id IN (
        SELECT id FROM info_type WHERE info = 'Plot'
    )
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name NOT LIKE '%Unknown%'
    AND (ci.note IS NULL OR ci.note != 'Cameo')
GROUP BY 
    ak.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT mk.keyword) > 0
ORDER BY 
    production_year DESC, company_count DESC;

### Explanation
- **CTE (`WITH RECURSIVE movie_hierarchy`)**: This recursive common table expression builds a hierarchy of movies linked by `movie_link`, capturing their relationships and depths.

- **SELECT clause**: It extracts actor names, titles of movies, production years, counts of associated companies, and keywords.

- **LEFT JOINs**: Several left joins ensure we gather optional data from related tables (`movie_companies`, `movie_info`, and `movie_keyword`).

- **Predicates/Expressions**: 
  - The `WHERE` clause filters out unknown names and cameo roles.
  - The `HAVING` clause ensures only movies with associated keywords are included.
  
- **Window Function**: The `RANK()` function computes a rank for movies based on company counts within the same year.

- **String Expressions & NULL Logic**: The checks for `NULL` values and string patterns help filter meaningful data while accounting for several semantic corner cases. 

- **Count Aggregations**: The counting of distinct companies and keywords provides insights into the broader context of each movie's production and marketing.
