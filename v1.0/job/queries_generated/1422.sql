WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rnk
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rnk <= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        TopMovies m
    LEFT OUTER JOIN movie_keyword mk ON m.title = (SELECT title FROM title WHERE id = mk.movie_id)
    LEFT OUTER JOIN keyword k ON mk.keyword_id = k.id
),
MovieCompanyInfo AS (
    SELECT 
        t.title,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CompanyKeywordSummary AS (
    SELECT 
        m.title,
        STRING_AGG(mk.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.company_name) AS total_companies
    FROM 
        MovieKeywords mk
    JOIN 
        MovieCompanyInfo mc ON mk.title = mc.title
    GROUP BY 
        m.title
)
SELECT 
    cks.title,
    cks.keywords,
    cks.total_companies,
    COALESCE(cks.keywords, 'No Keywords') AS keyword_summary,
    CASE 
        WHEN cks.total_companies > 3 THEN 'Many Companies'
        ELSE 'Few Companies'
    END AS company_summary
FROM 
    CompanyKeywordSummary cks
WHERE 
    cks.total_companies IS NOT NULL
ORDER BY 
    cks.total_companies DESC, cks.title;
