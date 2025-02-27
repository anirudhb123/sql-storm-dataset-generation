WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = 1 -- Assuming 1 represents 'movie'

    UNION ALL

    SELECT
        m.linked_movie_id,
        lm.title,
        lm.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title lm ON ml.linked_movie_id = lm.id
    WHERE
        mh.level < 3 -- limit hierarchy depth
),
GenreCounts AS (
    SELECT
        m.movie_id,
        COUNT(DISTINCT kg.keyword) AS genre_count
    FROM
        MovieHierarchy m
    LEFT JOIN
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN
        keyword kg ON mk.keyword_id = kg.id
    GROUP BY
        m.movie_id
),
ActorStats AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),
FullMovieStats AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(gc.genre_count, 0) AS genre_count,
        COALESCE(as.actor_count, 0) AS actor_count,
        COALESCE(as.actor_names, '') AS actor_names
    FROM
        MovieHierarchy mh
    LEFT JOIN
        GenreCounts gc ON mh.movie_id = gc.movie_id
    LEFT JOIN
        ActorStats as ON mh.movie_id = as.movie_id
)
SELECT
    f.movie_id,
    f.title,
    f.production_year,
    f.genre_count,
    f.actor_count,
    f.actor_names,
    RANK() OVER (ORDER BY f.actor_count DESC, f.genre_count ASC) AS rank
FROM
    FullMovieStats f
WHERE
    f.actor_count > 0
ORDER BY
    f.actor_count DESC,
    f.genre_count ASC
LIMIT 10;

This query performs the following tasks:

1. **Recursive CTE (`MovieHierarchy`)**: Tracks a hierarchy of movies starting from movies that are 'kind_id = 1'. It links to other movies up to 3 levels deep.
  
2. **Genre Counts CTE (`GenreCounts`)**: Aggregates the count of distinct genres related to movies from the `movie_keyword` and `keyword` tables.

3. **Actor Stats CTE (`ActorStats`)**: Counts distinct actors for each movie along with their names.

4. **Full Movie Stats CTE (`FullMovieStats`)**: Combines movie information with genre counts and actor statistics using a LEFT JOIN to ensure all movies are included.

5. **Final Selection**: Returns a list of movies sorted by the number of actors and genre count, ranking the movies by actor count (descending) and genre count (ascending). The result is limited to the top 10 movies based on the criteria.

The usage of outer joins, recursive CTEs, window functions, aggregations, and string expressions creates a rich dataset suitable for performance benchmarking.
