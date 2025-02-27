WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        r.role,
        a.name AS actor_name
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
GroupedMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors
    FROM 
        MovieDetails
    GROUP BY 
        title_id, title, production_year
)
SELECT 
    title_id,
    title,
    production_year,
    keywords,
    companies,
    actors
FROM 
    GroupedMovies
ORDER BY 
    production_year DESC, title;
