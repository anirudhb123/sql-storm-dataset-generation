WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        m.title AS movie_title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.movie_id = c.movie_id
    INNER JOIN
        title m ON a.movie_id = m.id
    GROUP BY
        a.id, m.title, a.production_year
),
CompanyMovies AS (
    SELECT
        mc.movie_id,
        cm.name AS company_name,
        ct.kind AS company_type,
        COUNT(m.id) AS total_movies_by_company
    FROM
        movie_companies mc
    JOIN
        company_name cm ON mc.company_id = cm.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN
        aka_title m ON mc.movie_id = m.movie_id
    WHERE
        cm.country_code IS NOT NULL
    GROUP BY
        mc.movie_id, cm.name, ct.kind
),
KeywordMovies AS (
    SELECT
        mk.movie_id,
        k.keyword AS movie_keyword,
        COUNT(*) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id, k.keyword
),
CombinedResults AS (
    SELECT
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.total_cast,
        cm.company_name,
        cm.company_type,
        COALESCE(km.keyword_count, 0) AS keyword_count
    FROM
        RankedMovies rm
    LEFT JOIN
        CompanyMovies cm ON rm.movie_id = cm.movie_id
    LEFT JOIN
        KeywordMovies km ON rm.movie_id = km.movie_id
)
SELECT
    movie_id,
    movie_title,
    production_year,
    total_cast,
    company_name,
    company_type,
    keyword_count,
    CASE 
        WHEN total_cast IS NULL OR total_cast = 0 THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_status,
    CASE 
        WHEN production_year < 2000 THEN 'Classic'
        WHEN production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_age_category
FROM
    CombinedResults
WHERE
    (keyword_count > 0 OR company_name IS NOT NULL)
ORDER BY
    production_year DESC, total_cast DESC NULLS LAST
LIMIT 100;
