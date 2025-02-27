WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        ci.nr_order AS cast_order,
        a.name AS actor_name,
        r.role AS actor_role
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
),
RankedMovies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.movie_id ORDER BY md.cast_order) AS actor_rank
    FROM 
        MovieDetails md
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    STRING_AGG(CONCAT(actor_name, ' (', actor_role, ')'), ', ' ORDER BY actor_rank) AS cast_details,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name, ', ') AS production_companies
FROM 
    RankedMovies
GROUP BY 
    movie_id, movie_title, production_year
ORDER BY 
    production_year DESC,
    movie_id;
