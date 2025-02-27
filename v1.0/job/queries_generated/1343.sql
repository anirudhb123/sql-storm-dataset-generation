WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
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
        k.keyword
    FROM 
        TopMovies tm
    JOIN 
        movie_keyword mk ON tm.title = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyMovies AS (
    SELECT 
        t.title,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        ct.kind AS company_type
    FROM 
        TopMovies t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    cm.title,
    cm.company_name,
    cm.company_type,
    mk.keyword
FROM 
    CompanyMovies cm
LEFT JOIN 
    MovieKeywords mk ON cm.title = mk.title
WHERE 
    cm.company_type IS NOT NULL
ORDER BY 
    cm.production_year DESC NULLS LAST, 
    cm.title;
