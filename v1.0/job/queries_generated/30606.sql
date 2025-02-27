WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.title IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level) AS movie_rank,
        COUNT(*) OVER (PARTITION BY mh.production_year) AS total_movies
    FROM
        MovieHierarchy mh
),
MovieGenres AS (
    SELECT
        mt.id AS movie_id,
        STRING_AGG(kt.keyword, ', ') AS genres
    FROM
        aka_title mt
    JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY
        mt.id
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.movie_rank,
        mg.genres
    FROM
        RankedMovies rm
    LEFT JOIN
        MovieGenres mg ON rm.movie_id = mg.movie_id
    WHERE
        rm.movie_rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.genres,
    COALESCE(CAST(ca.total_cast AS INTEGER), 0) AS total_cast,
    COALESCE(CAST(c.movie_id AS INTEGER), 0) AS important_movie_id
FROM 
    TopMovies tm
LEFT JOIN (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
) ca ON tm.movie_id = ca.movie_id
LEFT JOIN (
    SELECT 
        mc.movie_id,
        mc.company_id AS company_id
    FROM 
        movie_companies mc
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production' LIMIT 1)
) c ON tm.movie_id = c.movie_id
WHERE 
    tm.production_year BETWEEN 1990 AND 2020
ORDER BY 
    tm.production_year DESC, tm.title;
