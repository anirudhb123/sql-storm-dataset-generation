WITH ActorMovies AS (
    SELECT
        ka.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        COUNT(cc.id) AS cast_count,
        STRING_AGG(DISTINCT pt.kind, ', ') AS role_types
    FROM
        aka_name ka
    JOIN
        cast_info cc ON ka.person_id = cc.person_id
    JOIN
        aka_title at ON cc.movie_id = at.id
    JOIN
        role_type pt ON cc.person_role_id = pt.id
    GROUP BY
        ka.name, at.title, at.production_year
),
MovieKeywords AS (
    SELECT
        am.movie_title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        ActorMovies am
    JOIN
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = am.movie_title LIMIT 1)
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        am.movie_title
)
SELECT
    am.actor_name,
    am.movie_title,
    am.production_year,
    am.cast_count,
    mk.keywords
FROM
    ActorMovies am
JOIN
    MovieKeywords mk ON am.movie_title = mk.movie_title
ORDER BY
    am.production_year DESC,
    am.cast_count DESC,
    am.actor_name;
