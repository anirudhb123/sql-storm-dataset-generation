
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS main_actors,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year, t.kind_id
),
MovieDetails AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.cast_count,
        rm.main_actors,
        rm.keywords,
        ct.kind AS company_type
    FROM
        RankedMovies rm
    LEFT JOIN
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN
        company_type ct ON mc.company_type_id = ct.id
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.kind_id,
    md.cast_count,
    md.main_actors,
    md.keywords,
    md.company_type
FROM
    MovieDetails md
WHERE
    md.cast_count > 5
ORDER BY
    md.production_year DESC,
    md.cast_count DESC;
