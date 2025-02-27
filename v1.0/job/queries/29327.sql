WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        r.role,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, a.name, r.role
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_name,
        role,
        keyword_count,
        production_company_count
    FROM 
        MovieDetails
    WHERE 
        production_year >= 2000 AND
        keyword_count > 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_name,
    f.role,
    f.keyword_count,
    f.production_company_count
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, 
    f.keyword_count DESC, 
    f.actor_name;
