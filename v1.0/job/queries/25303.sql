WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rank
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
),
CastInfo AS (
    SELECT
        ci.movie_id,
        ci.person_id,
        a.name AS actor_name,
        rt.role AS role_name,
        COUNT(ci.id) AS role_count
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.movie_id, ci.person_id, a.name, rt.role
),
MovieInfoExtended AS (
    SELECT
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(DISTINCT ci.actor_name) AS actors,
        ARRAY_AGG(DISTINCT ci.role_name) AS roles,
        ARRAY_AGG(DISTINCT r.keyword) AS keywords,
        m.production_year,
        CASE 
            WHEN m.production_year < 2010 THEN 'Legacy Film'
            ELSE 'Modern Film'
        END AS film_type
    FROM
        aka_title m
    LEFT JOIN
        CastInfo ci ON m.id = ci.movie_id
    LEFT JOIN
        RankedMovies r ON m.id = r.movie_id
    GROUP BY
        m.id, m.title, m.production_year
)
SELECT
    movie_id,
    title,
    production_year,
    film_type,
    actors,
    roles,
    keywords
FROM
    MovieInfoExtended
WHERE
    film_type = 'Modern Film'
ORDER BY
    production_year DESC, title;
