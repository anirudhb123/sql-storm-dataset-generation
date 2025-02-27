
WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank,
        a.id
    FROM
        aka_title AS a
    JOIN movie_info AS mi ON a.id = mi.movie_id
    WHERE
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office')
        AND a.production_year >= 2000
),
DirectorInfo AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS director_count
    FROM
        cast_info AS ci
    JOIN role_type AS rt ON ci.person_role_id = rt.id
    WHERE
        rt.role = 'director'
    GROUP BY
        ci.movie_id
),
MoviesWithDirectors AS (
    SELECT
        rm.title,
        rm.production_year,
        d.director_count
    FROM
        RankedMovies AS rm
    LEFT JOIN DirectorInfo AS d ON rm.id = d.movie_id
)
SELECT
    mw.production_year,
    COUNT(*) AS total_movies,
    AVG(mw.director_count) AS avg_directors_per_movie,
    STRING_AGG(mw.title, ', ') AS movie_titles
FROM
    MoviesWithDirectors AS mw
GROUP BY
    mw.production_year
ORDER BY
    mw.production_year DESC
LIMIT 10;
