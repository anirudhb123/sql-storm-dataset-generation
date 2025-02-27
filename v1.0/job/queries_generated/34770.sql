WITH RECURSIVE MovieHierarchy AS (
    SELECT
        movie_id,
        title,
        production_year,
        1 AS level
    FROM
        aka_title
    WHERE
        season_nr IS NULL  -- Selecting movie titles (not episodes)

    UNION ALL

    SELECT
        m.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM
        movie_link m
    JOIN
        aka_title t ON m.linked_movie_id = t.movie_id
    JOIN
        MovieHierarchy mh ON m.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(cast_id) OVER (PARTITION BY mh.movie_id) AS cast_size,
        RANK() OVER (ORDER BY mh.production_year DESC) AS year_rank
    FROM
        MovieHierarchy mh
    LEFT JOIN
        cast_info c ON mh.movie_id = c.movie_id
),
PopularKeywords AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
    HAVING
        COUNT(mk.keyword_id) > 5  -- Filtering for movies with more than 5 keywords
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(rm.cast_size, 0) AS cast_size,
    COALESCE(pk.keyword_count, 0) AS keyword_count,
    CASE
        WHEN rm.year_rank <= 10 THEN 'Top 10 Recent Movies'
        ELSE 'Other Movies'
    END AS classification
FROM
    RankedMovies rm
LEFT JOIN
    PopularKeywords pk ON rm.movie_id = pk.movie_id
WHERE
    rm.production_year >= 2000  -- Considering movies from the year 2000 onward
ORDER BY
    rm.production_year DESC, rm.cast_size DESC;

This SQL query performs a comprehensive analysis of movies, their cast sizes, and popular keywords. It uses a recursive CTE to establish a hierarchy of movies based on linked movie relationships. It ranks the movies by their production year and provides a classification of 'Top 10 Recent Movies' or 'Other Movies' based on their rank. Additionally, it counts the number of keywords associated with each movie and incorporates advanced SQL concepts such as outer joins, window functions, and aggregated filtering.
