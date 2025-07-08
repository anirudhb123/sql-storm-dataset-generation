
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(c.person_id) AS role_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id, a.name, r.role
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ar.actor_name, 'No Actors') AS actor_name,
    ar.role_name,
    ar.role_count,
    mk.keywords
FROM
    RankedMovies rm
LEFT JOIN
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE
    rm.title_rank <= 5
ORDER BY
    rm.production_year DESC,
    rm.title ASC;
