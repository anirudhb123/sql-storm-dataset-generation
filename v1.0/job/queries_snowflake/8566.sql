
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        c.kind AS company_type, 
        kc.keyword AS movie_keyword, 
        rn.name AS person_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name rn ON ci.person_id = rn.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        company_type, 
        movie_keyword, 
        person_name 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 10
)
SELECT 
    production_year, 
    LISTAGG(title, ', ') WITHIN GROUP (ORDER BY title) AS titles, 
    LISTAGG(person_name, '; ') WITHIN GROUP (ORDER BY person_name) AS cast, 
    LISTAGG(company_type, ', ') WITHIN GROUP (ORDER BY company_type) AS companies, 
    LISTAGG(movie_keyword, ', ') WITHIN GROUP (ORDER BY movie_keyword) AS keywords
FROM 
    FilteredMovies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
