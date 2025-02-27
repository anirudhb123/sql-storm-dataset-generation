WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 5
),
MovieDetails AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(ci.role_id, 'Not Assigned') AS role_id,
        COUNT(DISTINCT m.name) AS company_count
    FROM
        TopMovies tm
    LEFT JOIN
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN
        company_name m ON mc.company_id = m.id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY
        tm.movie_id, tm.title, tm.production_year, ci.role_id
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.company_count,
    CASE 
        WHEN md.company_count > 3 THEN 'High'
        WHEN md.company_count BETWEEN 1 AND 3 THEN 'Medium'
        ELSE 'Low'
    END AS company_strength
FROM
    MovieDetails md
WHERE
    md.production_year >= 2000
ORDER BY
    md.production_year DESC, md.total_cast DESC
LIMIT 10
UNION ALL
SELECT 
    NULL AS movie_id,
    'Total Movies' AS title,
    NULL AS production_year,
    COUNT(*) AS total_cast,
    NULL AS company_count,
    NULL AS company_strength
FROM
    movie_companies;
