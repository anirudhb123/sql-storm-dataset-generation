
WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    GROUP BY
        t.title, t.production_year
),
CompanyStats AS (
    SELECT
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        complete_cast m ON mc.movie_id = m.movie_id
    GROUP BY
        m.movie_id
),
KeywordStats AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    COALESCE(rm.cast_count, 0) AS total_cast,
    COALESCE(cs.company_count, 0) AS total_companies,
    COALESCE(ks.keyword_count, 0) AS total_keywords
FROM
    RankedMovies rm
LEFT JOIN
    CompanyStats cs ON rm.production_year = cs.movie_id
LEFT JOIN
    KeywordStats ks ON rm.production_year = ks.movie_id
WHERE
    rm.rank <= 5
ORDER BY
    rm.production_year DESC, rm.cast_count DESC;
