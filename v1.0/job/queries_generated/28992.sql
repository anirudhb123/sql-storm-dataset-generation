WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM
        title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
FullCast AS (
    SELECT
        m.movie_id,
        a.name AS actor_name,
        c.nr_order,
        r.role
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
    JOIN
        RankedMovies m ON c.movie_id = m.movie_id
    WHERE
        m.year_rank <= 5
),
MovieInfo AS (
    SELECT
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_info
    FROM
        movie_info mi
    JOIN
        RankedMovies m ON mi.movie_id = m.movie_id
    GROUP BY
        m.movie_id
)
SELECT
    r.movie_id,
    r.movie_title,
    r.production_year,
    r.movie_keyword,
    fc.actor_name,
    fc.nr_order,
    fc.role,
    mi.movie_info
FROM
    RankedMovies r
JOIN
    FullCast fc ON r.movie_id = fc.movie_id
JOIN
    MovieInfo mi ON r.movie_id = mi.movie_id
ORDER BY
    r.production_year DESC, fc.nr_order;
