WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL AND
        t.title IS NOT NULL
),
CastRoles AS (
    SELECT
        ci.id AS cast_info_id,
        ci.person_id,
        ci.movie_id,
        cr.role AS role_name,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS role_count
    FROM
        cast_info ci
    JOIN
        role_type cr ON ci.role_id = cr.id
    WHERE
        ci.note IS NULL  -- Only including cast info without notes
),
KeywordCount AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
),
MovieDetails AS (
    SELECT
        m.id AS movie_id,
        t.title,
        t.production_year,
        cc.kind AS company_kind,
        kc.keyword_total,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        comp_cast_type cc ON mc.company_type_id = cc.id
    LEFT JOIN
        KeywordCount kc ON t.id = kc.movie_id
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    GROUP BY
        m.id, t.title, t.production_year, cc.kind, kc.keyword_total
)
SELECT
    md.title,
    COALESCE(md.production_year, 0) AS production_year_actual,
    md.company_kind,
    COALESCE(mk.keyword_total, 0) AS total_keywords,
    COUNT(cr.role_name) AS unique_roles,
    MAX(ROW_NUMBER() OVER (PARTITION BY md.movie_id ORDER BY md.production_year ASC)) AS highest_rank,
    STRING_AGG(DISTINCT cr.role_name, ', ') AS roles_list
FROM
    MovieDetails md
LEFT JOIN
    CastRoles cr ON md.movie_id = cr.movie_id
LEFT JOIN
    RankedTitles rt ON md.movie_id = rt.title_id
WHERE
    md.actor IS NULL OR md.actor IS NOT NULL // Demonstrating NULL logic
GROUP BY
    md.title, md.production_year, md.company_kind, mk.keyword_total
HAVING
    COUNT(DISTINCT cr.role_name) > 1 AND
    COALESCE(mk.keyword_total, 0) < 5
ORDER BY
    md.production_year DESC, 
    md.title ASC;
