WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        a.name AS actor_name, 
        r.role 
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
),
KeywordMovies AS (
    SELECT 
        rm.title, 
        COUNT(mk.keyword_id) AS keyword_count 
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.title = (SELECT title FROM title WHERE id = mk.movie_id)
    GROUP BY 
        rm.title
),
CompanyMovies AS (
    SELECT 
        rm.title, 
        c.name AS company_name 
    FROM 
        RankedMovies rm
    JOIN 
        movie_companies mc ON rm.title = (SELECT title FROM title WHERE id = mc.movie_id)
    JOIN 
        company_name c ON mc.company_id = c.id
)
SELECT 
    km.title, 
    km.keyword_count, 
    co.company_name
FROM 
    KeywordMovies km
LEFT JOIN 
    CompanyMovies co ON km.title = co.title
ORDER BY 
    km.keyword_count DESC, 
    co.company_name;
