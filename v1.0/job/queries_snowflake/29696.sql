
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
CompanyInfo AS (
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
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rt.title,
    rt.production_year,
    rt.title_rank,
    ac.actor_count,
    ci.company_name,
    ci.company_type,
    mk.keywords
FROM
    RankedTitles rt
LEFT JOIN
    ActorCounts ac ON rt.title_id = ac.movie_id
LEFT JOIN
    CompanyInfo ci ON rt.title_id = ci.movie_id
LEFT JOIN
    MovieKeywords mk ON rt.title_id = mk.movie_id
WHERE
    rt.production_year = 2023
ORDER BY
    rt.title_rank, rt.title;
