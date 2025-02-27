WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CastInfoWithRoles AS (
    SELECT
        ci.id AS cast_info_id,
        ci.person_id,
        ci.movie_id,
        c.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM
        cast_info ci
    JOIN
        role_type c ON ci.role_id = c.id
),
MoviesWithKeywords AS (
    SELECT
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mt
    JOIN
        keyword k ON mt.keyword_id = k.id
    GROUP BY
        mt.movie_id
),
Companies AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT
    rt.title,
    rt.production_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    ARRAY_AGG(DISTINCT cn.company_names) AS production_companies,
    kw.keywords,
    MAX(ci.role_name) AS prominent_role,
    CASE 
        WHEN MAX(rt.title_rank) < 5 THEN 'Low Rank Title'
        ELSE 'High Rank Title'
    END AS title_rank_category
FROM
    RankedTitles rt
LEFT JOIN
    CastInfoWithRoles ci ON rt.title_id = ci.movie_id
LEFT JOIN
    MoviesWithKeywords kw ON rt.title_id = kw.movie_id
LEFT JOIN
    Companies cn ON rt.title_id = cn.movie_id
GROUP BY
    rt.title, rt.production_year
HAVING
    COUNT(DISTINCT ci.person_id) > 1
    AND MAX(rt.production_year) >= 2000
ORDER BY
    rt.production_year DESC, actor_count DESC;
