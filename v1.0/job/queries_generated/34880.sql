WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, 
           COALESCE(mt.production_year, 'Unknown') AS production_year,
           1 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT m.id, m.title, 
           COALESCE(m.production_year, 'Unknown') AS production_year,
           mh.level + 1 AS level
    FROM aka_title m
    INNER JOIN movie_link ml ON m.id = ml.movie_id
    INNER JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    WHERE mh.level < 5  -- limit recursion depth
),

cast_roles AS (
    SELECT c.movie_id, 
           c.person_id,
           c.role_id,
           rn.role AS role_name,
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM cast_info c
    JOIN role_type rn ON c.role_id = rn.id
),

movie_keywords AS (
    SELECT m.id AS movie_id, 
           k.keyword,
           COUNT(mk.id) AS keyword_count
    FROM aka_title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id, k.keyword
)

SELECT mh.movie_id,
       mh.title,
       mh.production_year,
       COALESCE(a.name, 'No Actor') AS main_actor,
       STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
       COUNT(DISTINCT CAST(c.person_id AS INTEGER)) AS total_cast,
       MAX(kw.keyword_count) AS max_keyword_count
FROM movie_hierarchy mh
LEFT JOIN cast_roles c ON mh.movie_id = c.movie_id
LEFT JOIN aka_name a ON c.person_id = a.person_id AND a.name IS NOT NULL
LEFT JOIN movie_keywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN (
    SELECT k.keyword, 
           COUNT(*) AS keyword_count
    FROM movie_keywords k
    GROUP BY k.keyword
) kw ON mk.keyword = kw.keyword
WHERE mh.production_year > 2000
GROUP BY mh.movie_id, mh.title, mh.production_year, a.name
HAVING COUNT(DISTINCT c.person_id) > 0
ORDER BY mh.production_year DESC, max_keyword_count DESC;

This query demonstrates various advanced SQL concepts:

- A recursive CTE (`movie_hierarchy`) to build a hierarchy of movies.
- A CTE for retrieving cast roles (`cast_roles`) including window functions.
- A CTE to summarize keywords for each movie (`movie_keywords`).
- Multiple joins, including left joins to handle NULL values gracefully.
- Aggregate functions such as `COUNT` and `STRING_AGG` to gather information.
- Use of `COALESCE` for handling NULL logic.
- Filtering criteria and ordering to give meaningful results.

This extensive query could serve as a complex performance benchmark across large datasets within the `Join Order Benchmark` schema.
