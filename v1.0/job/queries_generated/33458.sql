WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    UNION ALL
    SELECT
        m.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM
        movie_link m
    JOIN
        title a ON m.linked_movie_id = a.id
    JOIN
        MovieHierarchy mh ON m.movie_id = mh.movie_id
),
CastDetails AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        array_agg(DISTINCT ak.name) AS actor_names
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
),
HighRatedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword_count, 0) AS keyword_count,
        COALESCE(c.actor_count, 0) AS actor_count,
        c.actor_names
    FROM
        title m
    LEFT JOIN
        MovieKeywords k ON m.id = k.movie_id
    LEFT JOIN
        CastDetails c ON m.id = c.movie_id
    WHERE
        m.production_year >= 2020
)
SELECT
    hm.level,
    hm.title,
    hm.production_year,
    hr.actor_count,
    hr.actor_names,
    hr.keyword_count,
    CASE
        WHEN hr.actor_count > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_status
FROM
    MovieHierarchy hm
JOIN
    HighRatedMovies hr ON hm.movie_id = hr.movie_id
ORDER BY
    hm.level DESC, hr.keyword_count DESC, hm.production_year ASC;
This SQL query performs the following:

1. **Recursive CTE**: `MovieHierarchy` builds a hierarchy of titles released since 2000, allowing us to track related movies.
2. **Aggregated Cast Data**: `CastDetails` computes the distinct count of actors and collects their names for each movie.
3. **Keyword Count**: `MovieKeywords` aggregates the count of keywords associated with each movie.
4. **High Rated Movies**: A final CTE `HighRatedMovies` compiles relevant movie information, such as actor count and keyword count for titles released in 2020 or later.
5. **Main Query**: Combines all this information, applying a conditional expression to output whether each movie has a cast or not, ordering by levels, keyword counts, and production years.
