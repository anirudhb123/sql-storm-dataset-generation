WITH RankedTitles AS (
    SELECT
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL AND
        t.title NOT LIKE '%%;%%%' -- excluding titles with semicolons
),
ActorMovieCount AS (
    SELECT
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        cast_info c
    GROUP BY
        c.person_id
),
CompanyInfo AS (
    SELECT
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        co.country_code IN ('US', 'UK') -- restrict to US and UK companies
),
KeywordCounts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
CompositeData AS (
    SELECT
        a.name AS actor_name,
        t.title,
        t.production_year,
        COALESCE(cc.company_name, 'Unknown') AS production_company,
        kc.keyword_count,
        ac.movie_count,
        CASE
            WHEN ac.movie_count > 5 THEN 'Prolific Actor'
            WHEN ac.movie_count BETWEEN 3 AND 5 THEN 'Emerging Actor'
            ELSE 'Newcomer'
        END AS actor_status
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN
        CompanyInfo cc ON t.id = cc.movie_id
    LEFT JOIN
        KeywordCounts kc ON t.id = kc.movie_id
    LEFT JOIN
        ActorMovieCount ac ON ci.person_id = ac.person_id
    WHERE
        t.production_year > 2000 -- filter to recent films
    ORDER BY
        t.production_year DESC,
        a.name
)
SELECT
    *,
    CASE
        WHEN production_year IS NULL THEN 'Year Not Listed'
        ELSE TO_CHAR(production_year)
    END AS production_year_display,
    CASE
        WHEN actor_name IS NULL THEN 'Missing Actor Name'
        ELSE actor_name
    END AS valid_actor_name,
    RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS keyword_rank
FROM
    CompositeData
WHERE
    (actor_name IS NOT NULL AND production_company IS NOT NULL)
    OR (actor_name IS NULL AND keyword_count > 2)
    OR (production_company IS NULL AND ac.movie_count < 3);
