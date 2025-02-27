WITH MovieYears AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id) AS rn
    FROM
        aka_title a
    WHERE
        a.production_year IS NOT NULL
),
ActorCount AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
MovieGenres AS (
    SELECT
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM
        movie_keyword mt
    JOIN
        keyword k ON mt.keyword_id = k.id
    GROUP BY
        mt.movie_id
),
TitledMovies AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        COALESCE(mg.genres, 'No genres') AS genres,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC, m.movie_id) AS overall_rank
    FROM
        MovieYears m
    LEFT JOIN
        ActorCount ac ON m.movie_id = ac.movie_id
    LEFT JOIN
        MovieGenres mg ON m.movie_id = mg.movie_id
)
SELECT
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.genres,
    (CASE 
         WHEN tm.actor_count >= 5 THEN 'Ensemble Cast'
         WHEN tm.actor_count = 0 THEN 'No Cast'
         ELSE 'Small Cast' 
     END) AS cast_description
FROM
    TitledMovies tm
WHERE
    tm.production_year BETWEEN 2000 AND 2020
    AND tm.actor_count > (SELECT AVG(actor_count) FROM ActorCount)
ORDER BY
    tm.production_year DESC,
    tm.title;
