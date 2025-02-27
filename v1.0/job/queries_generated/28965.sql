WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        a.production_year >= 2000 
        AND k.keyword ILIKE '%action%'
)

SELECT 
    movie_title,
    production_year,
    STRING_AGG(DISTINCT company_name, ', ') AS companies,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
FROM 
    RankedMovies
WHERE 
    rank = 1
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC;
