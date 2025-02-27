WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS cast_type,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(mc.company_id) AS production_companies
    FROM 
        aka_title t
    INNER JOIN 
        cast_info ci ON t.id = ci.movie_id
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    INNER JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, a.name, c.kind
), RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        cast_type,
        keywords,
        production_companies,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY production_companies DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    cast_type,
    keywords,
    production_companies
FROM 
    RankedMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year, production_companies DESC;
