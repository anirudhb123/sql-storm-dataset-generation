WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        c.name AS company_name,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, a.title, a.production_year, c.name
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_name,
    rm.keywords
FROM 
    RankedMovies rm
WHERE 
    rm.rn = 1
ORDER BY 
    rm.production_year DESC
LIMIT 50;
