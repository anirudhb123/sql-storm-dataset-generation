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
        c.movie_id,
        c.person_id,
        r.role,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
),
MovieCompaniesCounts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    GROUP BY
        mc.movie_id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS all_keywords
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
    MAX(c.winner) AS winning_cast,
    COALESCE(mcc.company_count, 0) AS num_companies,
    mk.all_keywords
FROM
    RankedTitles rt
LEFT JOIN
    CastInfoWithRoles c ON rt.title_id = c.movie_id AND c.total_cast > 5
LEFT JOIN
    MovieCompaniesCounts mcc ON rt.title_id = mcc.movie_id
LEFT JOIN
    MovieKeywords mk ON rt.title_id = mk.movie_id
WHERE
    rt.title_rank = 1
AND
    rt.production_year > 2000
GROUP BY
    rt.title, rt.production_year, mcc.company_count, mk.all_keywords
HAVING
    COUNT(c.person_id) > 10 OR MAX(c.role) IS NULL
ORDER BY
    rt.production_year DESC, rt.title;
