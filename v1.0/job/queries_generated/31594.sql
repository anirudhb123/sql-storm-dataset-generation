WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.production_year > 2000

    UNION ALL

    SELECT mt.movie_id, mt.title, mt.production_year, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.movie_id
    WHERE mh.level < 3
), actor_info AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    GROUP BY a.id, ak.name
), movie_keywords AS (
    SELECT
        mt.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.movie_id = mk.movie_id
    GROUP BY mt.id
), aggregated_info AS (
    SELECT
        mh.title,
        mh.production_year,
        ak.actor_name,
        ak.movie_count,
        mk.keywords,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY ak.movie_count DESC) AS actor_rank
    FROM movie_hierarchy mh
    JOIN actor_info ak ON mh.movie_id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = ak.actor_id)
    LEFT JOIN movie_keywords mk ON mh.movie_id = mk.movie_id 
    WHERE mh.production_year IS NOT NULL
)
SELECT 
    ai.title,
    ai.production_year,
    ai.actor_name,
    ai.movie_count,
    ai.keywords,
    CASE 
        WHEN ai.actor_rank <= 5 THEN 'Top Actor'
        ELSE 'Supporting Actor'
    END AS actor_grade
FROM aggregated_info ai
WHERE ai.movie_count > 3
ORDER BY ai.production_year DESC, ai.movie_count DESC;

This intricate SQL query uses various features including:
- A recursive CTE (`movie_hierarchy`) to traverse a hierarchy of linked movies released after 2000.
- An aggregated `actor_info` CTE to count the number of movies for each actor.
- A CTE for `movie_keywords` to aggregate keywords associated with movies.
- A final selection from an aggregated common table expression `aggregated_info`, which utilizes window functions to rank actors and categorize them.
- The query includes various join types and complex predicates, focusing on performance metrics and relationships within the movie dataset.
