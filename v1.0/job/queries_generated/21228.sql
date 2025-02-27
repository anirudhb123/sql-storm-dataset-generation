WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS rank_by_name
    FROM
        aka_title AS t
    JOIN
        cast_info AS c ON t.id = c.movie_id
    JOIN
        role_type AS r ON c.role_id = r.id
    JOIN
        aka_name AS a ON c.person_id = a.person_id
    WHERE
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
        AND r.role IS NOT NULL
    ORDER BY
        t.production_year DESC
),
MovieKeywords AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword AS mk
    JOIN
        keyword AS k ON mk.keyword_id = k.id
    JOIN
        aka_title AS m ON mk.movie_id = m.id
    GROUP BY
        m.movie_id
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM
        movie_companies AS mc
    JOIN
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT
    rm.title AS movie_title,
    rm.production_year,
    rm.role AS starring_role,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    COALESCE(mc.companies, 'No Companies') AS production_companies,
    (SELECT COUNT(*) FROM complete_cast WHERE movie_id = rm.id AND status_id = 1) AS complete_cast_count,
    COUNT(*) OVER (PARTITION BY rm.production_year) AS movies_in_year,
    CASE
        WHEN rm.rank_by_name = 1 THEN 'First in Cast'
        ELSE 'Not First in Cast'
    END AS cast_ranking
FROM
    RankedMovies AS rm
LEFT JOIN
    MovieKeywords AS mk ON rm.id = mk.movie_id
LEFT JOIN
    MovieCompanies AS mc ON rm.id = mc.movie_id
WHERE
    (rm.production_year >= 2000 OR rm.production_year IS NULL)
    AND (rm.role NOT LIKE '%Extra%' AND rm.role IS NOT NULL)
ORDER BY
    rm.production_year DESC,
    rm.title;
