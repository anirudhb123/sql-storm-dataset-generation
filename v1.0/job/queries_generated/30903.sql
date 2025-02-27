WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_movie_id
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL  -- Root movies
    UNION ALL
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mh.movie_id AS parent_movie_id
    FROM
        aka_title mt
    JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
MovieDetails AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        COALESCE(mc.id, 0) AS company_id,
        COALESCE(ca.person_id, 0) AS actor_id,
        COALESCE(a.name, 'Unknown Actor') AS actor_name,
        RANK() OVER (PARTITION BY mh.movie_id ORDER BY ca.nr_order) AS actor_rank
    FROM
        MovieHierarchy mh
    LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id AND mc.note IS NOT NULL
    LEFT JOIN cast_info ca ON mh.movie_id = ca.movie_id
    LEFT JOIN aka_name a ON ca.person_id = a.person_id
    WHERE
        mh.production_year > 2000  -- Filtering for movies after 2000
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.level,
    md.company_id,
    STRING_AGG(DISTINCT md.actor_name, ', ') AS actors,
    COUNT(DISTINCT md.actor_id) AS actor_count,
    CASE
        WHEN COUNT(md.actor_id) > 3 THEN 'Ensemble Cast'
        WHEN COUNT(md.actor_id) = 0 THEN 'No Cast'
        ELSE 'Small Cast'
    END AS cast_size_label
FROM
    MovieDetails md
GROUP BY
    md.movie_id, md.title, md.production_year, md.level, md.company_id
HAVING
    COUNT(md.actor_id) > 0  -- Only include movies with at least one actor
ORDER BY
    md.production_year DESC,
    md.level,
    actor_count DESC;

This complex SQL query achieves several objectives, including:

1. **Recursive CTE**: The `MovieHierarchy` CTE computes the hierarchy of movies and their respective episodes.
2. **Outer joins**: The `LEFT JOIN`s are used to include all movies, even if they have no associated companies or actors.
3. **Window functions**: `RANK()` is utilized to determine actor order within each movie.
4. **Aggregations**: `STRING_AGG` collects all actor names into a single string, while `COUNT` enumerates distinct actors.
5. **Conditional logic**: The `CASE` statement classifies the size of the cast based on the number of distinct actors.
6. **Filtering**: The query restricts results to movies released after the year 2000 and only includes those that have actors.

This query provides insights into movie production, cast dynamics, and company involvement across a varied dataset, making it ideal for performance benchmarking in a relational database environment.
