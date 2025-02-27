WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        mc.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        depth + 1
    FROM
        movie_link mc
        JOIN aka_title mt ON mc.movie_id = mt.id
        JOIN movie_hierarchy mh ON mh.movie_id = mc.movie_id
)
, actor_details AS (
    SELECT
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(extract(YEAR FROM CURRENT_DATE) - mt.production_year) AS avg_year_difference
    FROM
        cast_info ci
        JOIN aka_name ak ON ci.person_id = ak.person_id
        JOIN aka_title mt ON ci.movie_id = mt.id
    WHERE
        ak.name IS NOT NULL
    GROUP BY
        ak.name
)
SELECT
    mh.title AS movie_title,
    mh.production_year AS release_year,
    mh.depth,
    ad.name AS actor_name,
    ad.movie_count,
    ad.avg_year_difference,
    CASE 
        WHEN ad.movie_count > 5 THEN 'Frequent Actor'
        WHEN ad.movie_count BETWEEN 1 AND 5 THEN 'Occasional Actor'
        ELSE 'No Acting Credits'
    END AS actor_category,
    COALESCE(NULLIF(ad.name, ''), 'Unknown Actor') AS final_actor_name
FROM
    movie_hierarchy mh
LEFT JOIN actor_details ad ON mh.movie_id = ad.movie_count
WHERE
    (ad.movie_count IS NOT NULL OR mh.depth > 1)
ORDER BY
    mh.production_year DESC,
    mh.title
LIMIT 100;

This SQL query performs the following operations:

1. **Recursive CTE (Common Table Expression)**: `movie_hierarchy` builds a hierarchy of movies based on any links, tracking their depth based on connections to other movies.
  
2. **Actor Details CTE**: `actor_details` aggregates actor data, counting distinct movies and calculating the average year difference of their appearances.

3. **Final Selection**: The main query selects movie titles and actors, facilitates conditional logic for categorizing actors, and handles NULL logic with `COALESCE` and `NULLIF`.

4. **Use of Aggregates, Counts, and Conditions**: Multiple conditions and CASE statements illustrate actor categories based on their occurrances.

5. **Ordering and Limiting**: The output is ordered by the year of production and title, capped at retrieving the latest hundred records. 

This intricate setup allows for performance benchmarking across joins, aggregates, subqueries, and CTEs while reflecting complex relationships within the dataset.
