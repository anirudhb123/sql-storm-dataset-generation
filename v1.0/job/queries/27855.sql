WITH MovieDetails AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        k.keyword
    FROM
        title t
    JOIN
        cast_info ci ON ci.movie_id = t.id
    JOIN
        aka_name a ON a.person_id = ci.person_id
    JOIN
        movie_keyword mk ON mk.movie_id = t.id
    JOIN
        keyword k ON k.id = mk.keyword_id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword ILIKE '%action%'
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON c.id = mc.company_id
    JOIN
        company_type ct ON ct.id = mc.company_type_id
    WHERE
        mc.note IS NULL
),
FullDetails AS (
    SELECT
        md.title_id,
        md.title,
        md.production_year,
        md.actor_name,
        cd.company_name,
        cd.company_type
    FROM
        MovieDetails md
    LEFT JOIN
        CompanyDetails cd ON md.title_id = cd.movie_id
)
SELECT
    title_id,
    title,
    production_year,
    actor_name,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS companies
FROM
    FullDetails
GROUP BY
    title_id, title, production_year, actor_name
ORDER BY
    production_year DESC, title;
