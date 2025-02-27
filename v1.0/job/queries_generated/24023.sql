WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast_count
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
TopCastMovies AS (
    SELECT
        *
    FROM
        RankedMovies
    WHERE
        rank_by_cast_count = 1
),
CompanyInfo AS (
    SELECT
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies
    FROM
        movie_companies mc
    INNER JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
MovieDetails AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        ci.companies,
        COALESCE(ki.keyword, 'No Keywords') AS keyword,
        COUNT(mi.info) AS info_count
    FROM
        TopCastMovies m
    LEFT JOIN
        CompanyInfo ci ON m.movie_id = ci.movie_id
    LEFT JOIN
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY
        m.movie_id, m.title, m.production_year, ci.companies, ki.keyword
)
SELECT
    md.title,
    md.production_year,
    md.companies,
    md.keyword,
    md.info_count,
    CASE
        WHEN md.info_count > 5 THEN 'Highly Documented'
        WHEN md.info_count BETWEEN 3 AND 5 THEN 'Moderately Documented'
        ELSE 'Sparsely Documented'
    END AS documentation_status
FROM
    MovieDetails md
WHERE
    md.production_year BETWEEN 1990 AND 2023
    AND (md.companies IS NOT NULL OR md.keyword IS NOT NULL)
ORDER BY
    md.production_year DESC, 
    md.info_count DESC;
