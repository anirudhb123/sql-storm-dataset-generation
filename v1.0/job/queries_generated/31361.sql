WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 0 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT lm.id AS movie_id, lm.title, lm.production_year, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title lm ON ml.linked_movie_id = lm.id
),
cast_with_rank AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
),
movie_info_with_keyword AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COUNT(mk.keyword_id) AS total_keywords,
        STRING_AGG(mk.keyword, ', ') AS keyword_list
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY mt.id
)

SELECT 
    mh.title AS movie_title,
    mh.production_year,
    cwa.actor_name,
    cwa.actor_rank,
    mkw.total_keywords,
    mkw.keyword_list
FROM movie_hierarchy mh
LEFT JOIN cast_with_rank cwa ON mh.movie_id = cwa.movie_id
LEFT JOIN movie_info_with_keyword mkw ON mh.movie_id = mkw.movie_id
WHERE mh.production_year >= 2000
  AND (mkw.total_keywords IS NULL OR mkw.total_keywords > 3)
ORDER BY mh.production_year, cwa.actor_rank NULLS LAST;

In this SQL query:

1. **Recursive CTE (`movie_hierarchy`)**: Constructs a hierarchy of movies linked together, starting from "movies" based on `kind_id`.
2. **Window Function (`ROW_NUMBER()`)**: Ranks actors within each movie based on their order in the cast information.
3. **Aggregate Function (`STRING_AGG`)**: Gathers keywords associated with each movie into a single string.
4. **Complex Joins**: Several left joins to ensure that we get all desired information even if some movies or actors may not have all associated records.
5. **Filters and Predicates**: Conditions to filter movies released after 2000 and to include only movies with more than three keywords or none at all.
6. **Order By**: Sorting results primarily by year of production and then by actor rank, allowing NULL ranks to appear last.
