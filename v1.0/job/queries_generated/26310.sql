WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.company_id) AS company_count,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.company_id) DESC) AS production_rank
    FROM 
        aka_title t
    JOIN 
        movie_companies m ON t.id = m.movie_id
    JOIN 
        company_type c ON m.company_type_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        company_count,
        company_types
    FROM 
        RankedMovies
    WHERE 
        production_rank <= 5
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    t.company_count,
    t.company_types
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    TopMovies t ON ci.movie_id = t.movie_id
ORDER BY 
    t.production_year DESC, 
    t.company_count DESC;

This SQL query benchmarks string processing by extracting and presenting the top 5 movies per year (from 2000 to 2023) based on the number of companies associated with those movies. It utilizes common table expressions (CTEs) to rank movies and aggregate company types while efficiently joining several tables in the schema to produce a comprehensive result set that includes actor names, movie titles, production years, and details about company involvement.
