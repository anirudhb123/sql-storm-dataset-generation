
WITH RecursiveActorMovies AS (
    SELECT
        ka.person_id,
        kt.movie_id,
        kt.title,
        kt.production_year,
        ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY kt.production_year DESC) AS rn
    FROM
        aka_name ka
    JOIN
        cast_info ci ON ka.person_id = ci.person_id
    JOIN
        aka_title kt ON ci.movie_id = kt.movie_id
    WHERE
        kt.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT
        person_id,
        COUNT(*) AS movie_count
    FROM
        RecursiveActorMovies
    GROUP BY
        person_id
),
TopActors AS (
    SELECT
        kam.name,
        AMC.movie_count,
        kam.person_id
    FROM
        ActorMovieCount AMC
    JOIN
        aka_name kam ON AMC.person_id = kam.person_id
    WHERE
        AMC.movie_count > 5
    ORDER BY
        AMC.movie_count DESC
    LIMIT 10
),
ActorGenres AS (
    SELECT 
        ka.person_id,
        k.keyword AS genre,
        COUNT(k.keyword) AS genre_count
    FROM
        aka_name ka
    JOIN
        cast_info ci ON ka.person_id = ci.person_id
    JOIN
        movie_keyword mk ON ci.movie_id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        ka.person_id, k.keyword
    HAVING 
        COUNT(k.keyword) > 2
)
SELECT 
    T.name AS actor_name,
    T.movie_count,
    AG.genre,
    AG.genre_count
FROM 
    TopActors T
LEFT JOIN 
    ActorGenres AG ON T.person_id = AG.person_id
ORDER BY 
    T.movie_count DESC,
    AG.genre_count DESC;
