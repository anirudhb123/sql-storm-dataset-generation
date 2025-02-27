
WITH MovieTitles AS (
    SELECT
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        t.kind_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year, t.kind_id
),
CastInfo AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM
        cast_info ci
    JOIN
        aka_name p ON ci.person_id = p.person_id
    GROUP BY
        ci.movie_id
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT c.id) AS total_companies,
        STRING_AGG(DISTINCT cp.kind, ', ') AS company_types
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type cp ON mc.company_type_id = cp.id
    GROUP BY
        mc.movie_id
)
SELECT
    mt.title_id,
    mt.title,
    mt.production_year,
    mt.keywords,
    COALESCE(ci.total_cast, 0) AS total_cast,
    COALESCE(ci.cast_names, '') AS cast_names,
    COALESCE(co.total_companies, 0) AS total_companies,
    COALESCE(co.company_types, '') AS company_types
FROM
    MovieTitles mt
LEFT JOIN
    CastInfo ci ON mt.title_id = ci.movie_id
LEFT JOIN
    CompanyDetails co ON mt.title_id = co.movie_id
WHERE
    mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
ORDER BY
    mt.production_year DESC, mt.title;
