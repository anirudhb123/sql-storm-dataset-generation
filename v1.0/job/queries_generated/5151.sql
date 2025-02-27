WITH RankedMovies AS (
    SELECT 
        a.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, a.title) AS rn
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND c.country_code = 'USA'
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        company_name,
        keyword
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
)

SELECT 
    production_year,
    COUNT(*) AS movie_count,
    STRING_AGG(title, ', ') AS titles,
    STRING_AGG(DISTINCT company_name, ', ') AS companies,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords
FROM 
    FilteredMovies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
