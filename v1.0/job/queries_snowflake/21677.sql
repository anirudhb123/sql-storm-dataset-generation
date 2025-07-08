
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.movie_id = mk.movie_id
    WHERE
        mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'action%')
),
CastWithRoles AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        LISTAGG(DISTINCT rt.role, ', ') WITHIN GROUP (ORDER BY rt.role) AS roles
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.person_id
),
CompanyStats AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS note_presence
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id, cn.name
),
DetailedInfo AS (
    SELECT
        rk.title,
        rk.production_year,
        cnt.movie_count,
        co.company_name,
        co.company_count,
        co.note_presence,
        rk.rank_within_year
    FROM
        RankedTitles rk
    LEFT JOIN
        CastWithRoles cnt ON rk.title_id = cnt.person_id
    LEFT JOIN
        CompanyStats co ON rk.title_id = co.movie_id
)
SELECT
    di.title,
    di.production_year,
    COALESCE(di.movie_count, 0) AS total_actors,
    TRIM(di.company_name) AS production_company,
    di.company_count,
    di.note_presence,
    CASE 
        WHEN di.rank_within_year IS NULL THEN 'Not ranked'
        WHEN di.rank_within_year <= 5 THEN 'Top 5'
        ELSE 'Lower Tier'
    END AS ranking_description
FROM
    DetailedInfo di
WHERE
    di.production_year BETWEEN 2000 AND 2023
ORDER BY
    di.production_year DESC,
    di.title;
