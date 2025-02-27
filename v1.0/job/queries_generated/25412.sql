WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.name) AS actor_rank
    FROM
        title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE
        t.production_year IS NOT NULL
),
KeywordCounts AS (
    SELECT
        t.id AS title_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY
        t.id
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
CombinedDetails AS (
    SELECT
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.actor_name,
        kc.keyword_count,
        cd.company_name,
        cd.company_type
    FROM
        RankedTitles rt
    LEFT JOIN
        KeywordCounts kc ON rt.title_id = kc.title_id
    LEFT JOIN
        CompanyDetails cd ON rt.title_id = cd.movie_id
)
SELECT
    title_id,
    title,
    production_year,
    actor_name,
    keyword_count,
    company_name,
    company_type
FROM
    CombinedDetails
WHERE
    actor_rank <= 3 -- Top 3 actors for each production year
ORDER BY
    production_year DESC,
    title;
