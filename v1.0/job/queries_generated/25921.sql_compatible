
WITH MovieTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN
        aka_name c ON ci.person_id = c.person_id
    GROUP BY
        t.id, t.title, t.production_year, k.keyword
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
),
CompleteReport AS (
    SELECT
        mt.title_id,
        mt.title,
        mt.production_year,
        mt.movie_keyword,
        mt.cast_names,
        cd.company_names,
        cd.company_types
    FROM
        MovieTitles mt
    LEFT JOIN
        CompanyDetails cd ON mt.title_id = cd.movie_id
)
SELECT
    title,
    production_year,
    movie_keyword,
    cast_names,
    company_names,
    company_types
FROM
    CompleteReport
WHERE
    production_year BETWEEN 2000 AND 2020
ORDER BY
    production_year DESC, title;
