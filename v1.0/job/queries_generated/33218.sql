WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000  -- Filtering for movies produced in 2000 and later

    UNION ALL

    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.movie_id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    mh.title AS movie_title,
    mh.production_year,
    COALESCE(cast_members.actor_count, 0) AS main_cast_count,
    COALESCE(companies.company_count, 0) AS production_company_count,
    (SELECT COUNT(*)
     FROM movie_info mi
     WHERE mi.movie_id = mh.movie_id
       AND mi.info LIKE '%oscar%') AS oscar_wins,
    DENSE_RANK() OVER (ORDER BY mh.production_year DESC) AS rank_by_year
FROM
    MovieHierarchy mh

LEFT JOIN (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    WHERE
        rt.role = 'actor'
    GROUP BY
        ci.movie_id
) AS cast_members ON mh.movie_id = cast_members.movie_id

LEFT JOIN (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        ct.kind = 'production'
    GROUP BY
        mc.movie_id
) AS companies ON mh.movie_id = companies.movie_id

WHERE
    mh.level = 0  -- Only top-level movies (not linked)
ORDER BY
    mh.production_year DESC,
    mh.title;
This SQL query does the following:

1. Creates a recursive Common Table Expression (CTE) called `MovieHierarchy` that constructs a hierarchy of movies linked together through `movie_link`.
2. Filters for movies produced from the year 2000 onwards.
3. Utilizes `LEFT JOIN` to count the distinct actors in the main cast (`cast_members`) and distinct production companies (`companies`).
4. Uses a correlated subquery to count the number of times "oscar" appears in `movie_info` for each movie.
5. Applies a window function `DENSE_RANK()` to rank the movies by production year.
6. Ensures that only top-level movies (those with no parent links) are included in the final output.
7. Orders the results by the production year (descending) and movie title alphabetically.
