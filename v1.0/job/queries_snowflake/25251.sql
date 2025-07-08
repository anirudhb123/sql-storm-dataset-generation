WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY
        t.id, t.title, t.production_year
),
SelectedMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM
        RankedMovies rm
    WHERE
        rm.cast_count > 5 
),
ActorDetails AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        r.role AS role_in_movie,
        t.production_year
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        SelectedMovies t ON ci.movie_id = t.movie_id
    JOIN
        role_type r ON ci.role_id = r.id
)
SELECT
    ad.actor_name,
    ad.movie_title,
    ad.role_in_movie,
    ad.production_year,
    COUNT(DISTINCT ci.movie_id) AS total_movies_actor
FROM
    ActorDetails ad
JOIN
    cast_info ci ON ad.movie_title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
GROUP BY
    ad.actor_name, ad.movie_title, ad.role_in_movie, ad.production_year
ORDER BY
    total_movies_actor DESC, ad.actor_name;