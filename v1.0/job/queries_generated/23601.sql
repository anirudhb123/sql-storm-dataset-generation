WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.title AS movie_title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM
        movie_link ml
    JOIN
        title mt ON ml.movie_id = mt.id
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
    
    UNION ALL
    
    SELECT
        mt.title AS movie_title,
        mt.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        title mt ON ml.linked_movie_id = mt.id
    JOIN
        movie_hierarchy mh ON mh.linked_movie_id = ml.movie_id
),
actor_performance AS (
    SELECT
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(CASE
            WHEN mt.production_year IS NOT NULL THEN mt.production_year
            ELSE NULL
        END) AS avg_production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rn
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN
        aka_title at ON ci.movie_id = at.movie_id
    LEFT JOIN
        title mt ON at.movie_id = mt.id
    GROUP BY
        ak.id
),
keyword_analysis AS (
    SELECT
        mk.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords,
        COUNT(mk.id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_title,
    mh.production_year,
    a.actor_name,
    a.movie_count,
    a.avg_production_year,
    COALESCE(ka.keywords, 'No keywords') AS keywords,
    ka.keyword_count
FROM
    movie_hierarchy mh
JOIN
    actor_performance a ON a.rn <= 5  -- Top 5 actors
LEFT JOIN
    keyword_analysis ka ON mh.linked_movie_id = ka.movie_id
WHERE
    mh.level = 1
ORDER BY
    mh.production_year DESC,
    a.movie_count DESC,
    mh.movie_title ASC
LIMIT 100;

### Explanation:
- The query consists of three Common Table Expressions (CTEs):
  1. **movie_hierarchy**: A recursive CTE that builds a hierarchy of movies linked by sequels. It captures all sequels recursively.
  2. **actor_performance**: This CTE aggregates actor data to find the top actors based on movie count and average production year of the movies they acted in.
  3. **keyword_analysis**: This CTE aggregates keywords associated with each movie, counting the keywords and creating a concatenated string of them.

- After defining the CTEs, the main query:
  - Joins these CTEs to display details about movies, actors, and associated keywords.
  - Filters to grab only the first level of movie sequences (direct sequels).
  - It limits the results to include only the most active actors (limited to the top 5).
  
- Several SQL constructs are included, such as:
  - `JOIN`, `LEFT JOIN` to handle relationships.
  - `ROW_NUMBER()` window function to rank the actors.
  - `STRING_AGG` to consolidate keywords.
  - `COALESCE` to handle potentially NULL keyword results.
  
- The complexity comes from the recursive nature of the movie hierarchy and the various aggregations and calculations, demonstrating advanced SQL capabilities while also tackling nuances like handling NULL values and positional ranking.
