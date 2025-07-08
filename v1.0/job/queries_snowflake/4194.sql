WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS ranking
    FROM 
        title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.movie_title,
    m.production_year,
    COALESCE(cd.total_companies, 0) AS total_company_count,
    COALESCE(ks.keyword_count, 0) AS total_keywords,
    RANK() OVER (ORDER BY m.production_year) AS year_rank
FROM 
    RankedMovies m
LEFT JOIN 
    CompanyDetails cd ON m.movie_id = cd.movie_id
LEFT JOIN 
    KeywordStats ks ON m.movie_id = ks.movie_id
WHERE 
    m.ranking <= 5
ORDER BY 
    m.production_year DESC, 
    m.movie_title;
