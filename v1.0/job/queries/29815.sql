
WITH MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT CONCAT(p.name, ' (', rt.role, ')'), ', ') AS cast_info,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        title m
        JOIN complete_cast cc ON m.id = cc.movie_id
        JOIN cast_info ci ON cc.subject_id = ci.person_id
        JOIN role_type rt ON ci.role_id = rt.id
        JOIN aka_name p ON ci.person_id = p.person_id
        LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
        LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id, m.title, m.production_year
),
CompanyInfo AS (
    SELECT
        m.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM
        movie_companies m
        JOIN company_name c ON m.company_id = c.id
        JOIN company_type ct ON m.company_type_id = ct.id
    GROUP BY
        m.movie_id
),
MovieInfo AS (
    SELECT
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.cast_info,
        md.keywords,
        ci.companies,
        ci.company_types
    FROM
        MovieDetails md
        LEFT JOIN CompanyInfo ci ON md.movie_id = ci.movie_id
)
SELECT
    movie_id,
    movie_title,
    production_year,
    cast_info,
    keywords,
    companies,
    company_types
FROM
    MovieInfo
WHERE
    production_year >= 2000
ORDER BY
    production_year DESC,
    movie_title;
