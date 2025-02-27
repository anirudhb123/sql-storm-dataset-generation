
WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title AS title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
),

CastDetails AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actors
    FROM
        cast_info ci
    JOIN
        aka_name an ON ci.person_id = an.person_id
    GROUP BY
        ci.movie_id
)

SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    COALESCE(cd.cast_count, 0) AS cast_count,
    COALESCE(cd.actors, '') AS actors
FROM
    MovieDetails md
LEFT JOIN
    CastDetails cd ON md.movie_id = cd.movie_id
ORDER BY
    md.production_year DESC, 
    cast_count DESC;
