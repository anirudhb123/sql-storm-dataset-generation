
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
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
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        company_name, 
        keyword
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    movie_title,
    production_year,
    company_name,
    LISTAGG(keyword, ', ') WITHIN GROUP (ORDER BY keyword) AS keywords
FROM 
    TopMovies
GROUP BY 
    movie_title, 
    production_year, 
    company_name
ORDER BY 
    production_year DESC, 
    movie_title;
