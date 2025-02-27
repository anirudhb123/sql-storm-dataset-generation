WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ca ON ca.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        company.name AS company_name,
        c.role AS role_type
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = tm.movie_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = tm.movie_id
    LEFT JOIN 
        company_name company ON company.id = mc.company_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = tm.movie_id
    LEFT JOIN 
        role_type c ON c.id = ci.role_id
)
SELECT 
    d.title,
    d.production_year,
    STRING_AGG(DISTINCT d.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT d.company_name, ', ') AS companies,
    STRING_AGG(DISTINCT d.role_type, ', ') AS roles
FROM 
    MovieDetails d
GROUP BY 
    d.title, d.production_year
HAVING 
    COUNT(DISTINCT d.role_type) > 0
ORDER BY 
    d.production_year DESC, 
    d.title;
