WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
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
        rn <= 5
),
MovieKeywords AS (
    SELECT 
        t.title,
        k.keyword
    FROM 
        TopMovies tm
    JOIN 
        aka_title t ON t.title = tm.title AND t.production_year = tm.production_year
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyInfo AS (
    SELECT 
        t.title,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        TopMovies tm
    JOIN 
        aka_title t ON t.title = tm.title AND t.production_year = tm.production_year
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.title
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(k.keyword, 'No Keywords') AS keyword,
    COALESCE(c.companies, 'No Companies') AS production_companies,
    m.actor_count
FROM 
    TopMovies m
LEFT JOIN 
    MovieKeywords k ON m.title = k.title
LEFT JOIN 
    CompanyInfo c ON m.title = c.title
ORDER BY 
    m.production_year DESC, 
    m.actor_count DESC;
