
WITH MovieDetails AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles_assigned
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.title, t.production_year
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS companies_involved
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id, co.name, ct.kind
),
KeywordDetails AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)

SELECT
    md.title,
    md.production_year,
    md.total_cast,
    md.avg_roles_assigned,
    cd.company_name,
    cd.company_type,
    cd.companies_involved,
    kd.keywords
FROM
    MovieDetails md
LEFT JOIN
    CompanyDetails cd ON md.production_year = cd.movie_id
LEFT JOIN
    KeywordDetails kd ON md.production_year = kd.movie_id
WHERE
    md.total_cast > 5
ORDER BY
    md.production_year DESC, md.total_cast DESC
LIMIT 20;
