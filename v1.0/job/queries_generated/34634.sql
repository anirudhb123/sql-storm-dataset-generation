WITH RECURSIVE MovieHierarchy AS (
    -- Recursive Common Table Expression to find all movies and their linked movies
    SELECT
        m.id AS movie_id,
        m.title,
        ml.linked_movie_id,
        1 AS level
    FROM
        title m
    LEFT JOIN
        movie_link ml ON m.id = ml.movie_id

    UNION ALL

    SELECT
        mh.movie_id,
        mh.title,
        ml.linked_movie_id,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.linked_movie_id = ml.movie_id
),
RankedMovies AS (
    -- CTE for ranking movies by the number of links and their production year
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(ml.linked_movie_id) AS link_count,
        RANK() OVER (ORDER BY COUNT(ml.linked_movie_id) DESC, m.production_year ASC) AS movie_rank
    FROM
        title m
    LEFT JOIN
        movie_link ml ON m.id = ml.movie_id
    GROUP BY
        m.id
),
TopMovies AS (
    -- Select top 10 movies based on the rank
    SELECT
        movie_id,
        title,
        production_year
    FROM
        RankedMovies
    WHERE
        movie_rank <= 10
),
DetailedMovieInfo AS (
    -- Gather detailed information on top movies including cast and keywords
    SELECT
        tm.movie_id,
        tm.title,
        tm.production_year,
        ka.name AS actor_name,
        kw.keyword
    FROM
        TopMovies tm
    LEFT JOIN
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN
        aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN
        keyword kw ON mk.keyword_id = kw.id
)
SELECT 
    dmi.movie_id,
    dmi.title,
    dmi.production_year,
    STRING_AGG(DISTINCT dmi.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT dmi.keyword, ', ') AS keywords
FROM
    DetailedMovieInfo dmi
GROUP BY
    dmi.movie_id, dmi.title, dmi.production_year
ORDER BY
    dmi.production_year DESC;

