WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM aka_title mt
    WHERE mt.production_year > 2000

    UNION ALL

    SELECT
        linked.movie_id,
        lt.title,
        lt.production_year,
        lt.kind_id,
        mh.depth + 1
    FROM movie_link ml
    JOIN title lt ON ml.linked_movie_id = lt.id
    JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

, RankedCast AS (
    SELECT
        ci.movie_id,
        ak.name AS actor,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_rank
    FROM cast_info ci
    JOIN aka_name ak ON ak.person_id = ci.person_id
)

, MovieInfo AS (
    SELECT
        mt.movie_id,
        COUNT(DISTINCT ki.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword ki ON mk.keyword_id = ki.id
    JOIN aka_title mt ON mt.id = mk.movie_id
    GROUP BY mt.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mc.keyword_count,
    rk.actor,
    CASE
        WHEN mc.keyword_count IS NULL THEN 'No Keywords'
        ELSE mc.keyword_count::text
    END AS keyword_info,
    MAX(CASE WHEN rk.actor_rank = 1 THEN rk.actor END) AS lead_actor,
    COUNT(DISTINCT rk.actor) AS total_actors
FROM MovieHierarchy mh
LEFT JOIN MovieInfo mc ON mh.movie_id = mc.movie_id
LEFT JOIN RankedCast rk ON mh.movie_id = rk.movie_id
GROUP BY mh.movie_id, mh.title, mh.production_year, mc.keyword_count, rk.actor
HAVING COUNT(DISTINCT rk.actor) > 3
ORDER BY mh.production_year DESC, mh.title;

### Explanation:
- **Common Table Expressions (CTEs)**: The query uses three CTEs. 
  - **MovieHierarchy**: Retrieves movies produced after 2000, including links to other movies for a hierarchy.
  - **RankedCast**: Ranks actors in each movie based on their names.
  - **MovieInfo**: Counts distinct keywords for each movie.

- **LEFT JOIN**: The main query combines the results from these CTEs using left joins.

- **NULL Logic**: The `CASE` statement handles NULL values in the keyword count to display a meaningful string.

- **Aggregates and Window Functions**: It utilizes `ROW_NUMBER()` for actor ranking and `COUNT()` for total actors per movie.

- **Complicated Predicate**: The `HAVING` clause filters results to only include movies with more than 3 distinct actors.

- **ORDER BY**: The results are sorted by production year and title in descending order.

This query can serve as an intricate benchmark for performance evaluations by pulling together multiple logical layers and data manipulations.
