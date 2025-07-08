
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        p.name AS person_name,
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
    JOIN 
        cast_info ca ON a.id = ca.movie_id
    JOIN 
        aka_name p ON ca.person_id = p.person_id
    WHERE 
        a.production_year > 2000
        AND k.keyword ILIKE '%drama%'
),
FilteredMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        movie_keyword, 
        company_name, 
        person_name
    FROM 
        RankedMovies
    WHERE 
        rank = 1
)
SELECT 
    movie_title, 
    production_year, 
    LISTAGG(DISTINCT movie_keyword, ', ') WITHIN GROUP (ORDER BY movie_keyword) AS keywords,
    LISTAGG(DISTINCT company_name, ', ') WITHIN GROUP (ORDER BY company_name) AS production_companies,
    LISTAGG(DISTINCT person_name, ', ') WITHIN GROUP (ORDER BY person_name) AS cast_members
FROM 
    FilteredMovies
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC;
