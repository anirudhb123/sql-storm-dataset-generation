WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.id) DESC) AS rank
    FROM
        aka_title AS t
    LEFT JOIN
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name AS m ON mc.company_id = m.id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id
),
ActorRoles AS (
    SELECT
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS actor_role,
        COUNT(DISTINCT ci.id) AS role_count
    FROM
        cast_info AS ci
    JOIN
        aka_name AS a ON ci.person_id = a.person_id
    JOIN
        role_type AS rt ON ci.role_id = rt.id
    GROUP BY
        ci.movie_id, a.name, rt.role
),
MoviesWithKeywords AS (
    SELECT
        t.id AS movie_id,
        t.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        aka_title AS t
    LEFT JOIN
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY
        t.id
)
SELECT
    rm.title AS movie_title,
    rm.production_year,
    COALESCE(ar.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(ar.actor_role, 'Unknown Role') AS actor_role,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    rm.company_count
FROM
    RankedMovies AS rm
LEFT JOIN
    ActorRoles AS ar ON rm.movie_id = ar.movie_id
LEFT JOIN
    MoviesWithKeywords AS mk ON rm.movie_id = mk.movie_id
WHERE
    rm.rank <= 3
ORDER BY
    rm.production_year DESC, rm.company_count DESC, rm.title;
