WITH MovieRanked AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.movie_id = c.movie_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
),
CompanyInfo AS (
    SELECT
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies,
        MAX(ct.kind) AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
),
KeywordStats AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    m.cast_count,
    COALESCE(ci.companies, 'No Companies') AS companies_involved,
    COALESCE(ks.keyword_count, 0) AS total_keywords,
    COALESCE(m.year_rank, 0) AS rank_in_year,
    CASE 
        WHEN COALESCE(ks.keyword_count, 0) > 0 THEN 'Has Keywords'
        ELSE 'No Keywords'
    END AS keyword_status
FROM
    MovieRanked m
LEFT JOIN
    CompanyInfo ci ON m.movie_id = ci.movie_id
LEFT JOIN
    KeywordStats ks ON m.movie_id = ks.movie_id
WHERE
    m.year_rank <= 5
ORDER BY
    m.production_year DESC, m.cast_count DESC;
