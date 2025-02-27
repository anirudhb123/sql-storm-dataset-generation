WITH ActorMovies AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS actor_role
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        title t ON ci.movie_id = t.id
    JOIN
        role_type r ON ci.role_id = r.id
    WHERE
        a.name LIKE '%Smith%'
        AND t.production_year >= 2000
),
MovieKeywords AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
    GROUP BY
        m.movie_id
),
MoviesWithKeyword AS (
    SELECT
        am.actor_id,
        am.actor_name,
        am.movie_title,
        am.production_year,
        am.actor_role,
        mk.keywords
    FROM
        ActorMovies am
    LEFT JOIN
        MovieKeywords mk ON am.production_year = mk.movie_id
)
SELECT 
    actor_id,
    actor_name,
    movie_title,
    production_year,
    actor_role,
    keywords
FROM
    MoviesWithKeyword
ORDER BY
    production_year DESC,
    actor_name;
