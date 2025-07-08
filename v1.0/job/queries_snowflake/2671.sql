WITH MovieCounts AS (
    SELECT
        ct.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM
        complete_cast ct
    LEFT JOIN
        cast_info ci ON ct.movie_id = ci.movie_id
    LEFT JOIN
        movie_companies mc ON ct.movie_id = mc.movie_id
    GROUP BY
        ct.movie_id
),
MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mc.total_cast, 0) AS total_cast,
        COALESCE(mc.total_companies, 0) AS total_companies,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank
    FROM
        aka_title m
    LEFT JOIN
        MovieCounts mc ON m.id = mc.movie_id
    WHERE
        m.production_year IS NOT NULL
)
SELECT
    md.title,
    md.production_year,
    md.total_cast,
    md.total_companies,
    NULLIF(md.total_cast, 0) AS non_zero_cast,
    CASE
        WHEN md.total_companies > 10 THEN 'Many Companies'
        WHEN md.total_companies BETWEEN 1 AND 10 THEN 'Few Companies'
        ELSE 'No Companies'
    END AS company_status
FROM
    MovieDetails md
WHERE
    md.rank <= 5
ORDER BY
    md.production_year DESC, md.total_cast DESC;

