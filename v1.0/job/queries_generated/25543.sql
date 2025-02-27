WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        p.info AS person_info,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY t.production_year DESC) AS ranking
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        t.production_year >= 2000
    AND 
        c.kind ILIKE '%production%'
),
TopMovies AS (
    SELECT 
        aka_name,
        movie_title,
        production_year,
        company_type,
        person_info
    FROM 
        RankedMovies
    WHERE 
        ranking = 1
)
SELECT 
    aka_name,
    movie_title,
    production_year,
    company_type,
    person_info
FROM 
    TopMovies
ORDER BY 
    production_year DESC, aka_name;
