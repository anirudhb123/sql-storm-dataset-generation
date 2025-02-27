WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actors_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        aka_title a
    JOIN
        cast_info c ON a.id = c.movie_id
    JOIN
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        a.production_year >= 2000
    GROUP BY
        a.id, a.title, a.production_year
),
MovieInfo AS (
    SELECT
        r.movie_id,
        r.title,
        r.production_year,
        r.actors_count,
        r.actor_names,
        COALESCE(mi.info, 'No additional info') AS additional_info
    FROM
        RankedMovies r
    LEFT JOIN
        movie_info mi ON r.movie_id = mi.movie_id
    WHERE
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    m.actors_count,
    m.actor_names,
    m.additional_info
FROM
    MovieInfo m
ORDER BY
    m.production_year DESC, m.actors_count DESC
LIMIT 10;
