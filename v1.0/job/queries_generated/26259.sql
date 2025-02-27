WITH MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(c.id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM
        aka_title ak
    JOIN
        title m ON ak.movie_id = m.id
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY
        m.id, m.title, m.production_year
),
CompanySales AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
)
SELECT
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.total_cast,
    md.aliases,
    md.keywords,
    cs.companies,
    cs.company_types
FROM
    MovieDetails md
LEFT JOIN
    CompanySales cs ON md.movie_id = cs.movie_id
WHERE
    md.production_year >= 2000
ORDER BY
    md.total_cast DESC,
    md.production_year DESC;
