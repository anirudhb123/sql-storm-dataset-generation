
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM
        aka_title AS t
    WHERE
        t.production_year IS NOT NULL
),
CompanyStats AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT c.name) AS unique_companies,
        SUM(CASE WHEN ct.kind LIKE 'Distributor%' THEN 1 ELSE 0 END) AS distributor_count
    FROM
        movie_companies AS mc
    JOIN
        company_name AS c ON mc.company_id = c.id
    JOIN
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
),
MovieKeywordStats AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword AS mk
    JOIN
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
CastRoleCounts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT ci.role_id) FILTER (WHERE ci.note IS NOT NULL) AS cast_with_notes
    FROM
        cast_info AS ci
    GROUP BY
        ci.movie_id
)
SELECT
    rt.title,
    rt.production_year,
    rt.total_titles,
    cs.unique_companies,
    cs.distributor_count,
    cr.total_cast,
    cr.cast_with_notes,
    CASE 
        WHEN cr.total_cast > 0 THEN ROUND((cast(cr.cast_with_notes AS numeric) / cr.total_cast) * 100, 2)
        ELSE NULL 
    END AS casting_note_percentage,
    CASE 
        WHEN rt.title_rank = 1 THEN 'First Title of Year'
        WHEN rt.title_rank = rt.total_titles THEN 'Last Title of Year'
        ELSE 'Middle Title' 
    END AS title_position,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords
FROM
    RankedTitles AS rt
LEFT JOIN
    CompanyStats AS cs ON rt.title_id = cs.movie_id
LEFT JOIN
    CastRoleCounts AS cr ON rt.title_id = cr.movie_id
LEFT JOIN
    MovieKeywordStats AS mk ON rt.title_id = mk.movie_id
WHERE
    rt.production_year = (
        SELECT MAX(production_year) FROM aka_title
    )
ORDER BY
    rt.production_year DESC,
    rt.title;
