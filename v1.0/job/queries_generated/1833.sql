WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS year_rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        year_rank <= 5
),
MovieKeywords AS (
    SELECT 
        t.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (
            SELECT id FROM title WHERE title = tm.title AND production_year = tm.production_year
        )
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title
),
MovieCompanies AS (
    SELECT 
        t.title,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.title
)
SELECT 
    mk.title,
    mk.keywords,
    mc.companies,
    CASE 
        WHEN mk.keywords IS NOT NULL THEN 'Keywords Available'
        ELSE 'No Keywords'
    END AS keyword_status
FROM 
    MovieKeywords mk
LEFT JOIN 
    MovieCompanies mc ON mk.title = mc.title
WHERE 
    mk.title IS NOT NULL 
    AND (mc.companies IS NOT NULL OR mc.companies IS NULL)
ORDER BY 
    mk.title;
