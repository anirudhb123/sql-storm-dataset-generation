WITH RECURSIVE MovieHierarchy AS (
    -- Base case: select all root movies (having no episodes)
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM title t
    WHERE t.episode_of_id IS NULL

    UNION ALL

    -- Recursive case: select episodes for each movie
    SELECT
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM title e
    JOIN MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),

RankedCast AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
),

MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(RC.actor_count, 0) AS actor_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE
        WHEN mh.level = 1 THEN 'Root Movie'
        ELSE 'Episode'
    END AS movie_type
FROM MovieHierarchy mh
LEFT JOIN (
    SELECT
        movie_id,
        COUNT(*) AS actor_count
    FROM RankedCast
    GROUP BY movie_id
) RC ON mh.movie_id = RC.movie_id
LEFT JOIN MovieKeywords mk ON mh.movie_id = mk.movie_id
ORDER BY mh.production_year DESC, mh.movie_id;

### Explanation:
1. **CTE for Movie Hierarchy**: A recursive CTE, `MovieHierarchy`, is established to create a hierarchy of movies including episodes. It selects all root movies first and recursively adds any associated episodes.

2. **Ranked Cast**: Another CTE, `RankedCast`, retrieves actors for each movie, ranking them based on the order in which they appear in the credits using `ROW_NUMBER()`.

3. **Keywords Aggregation**: `MovieKeywords` aggregates keywords associated with each movie, concatenating them into a single string for better readability.

4. **Final Selection**: The final query selects from the movie hierarchy while left joining to get the number of actors and aggregated keywords. It also assigns a string indicating whether the movie is a root movie or an episode.

5. **Ordering**: The result is ordered by production year and movie ID, helping to analyze the data trends over time.

This elaborate query showcases various SQL features such as CTEs, window functions, and COALESCE for handling NULLs, while combining data across different tables in a meaningful way for benchmarking purposes.
