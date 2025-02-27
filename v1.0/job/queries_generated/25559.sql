WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        r.role AS actor_role,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        c.kind AS company_type,
        COUNT( DISTINCT mc.company_id ) AS num_companies
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        role_type r ON r.id = ci.role_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_type c ON c.id = mc.company_type_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, ak.name, r.role, c.kind
),
ActorStats AS (
    SELECT 
        actor_name,
        COUNT(*) AS movie_count,
        MIN(production_year) AS first_movie_year,
        MAX(production_year) AS last_movie_year,
        GROUP_CONCAT(DISTINCT movie_title ORDER BY production_year) AS movies
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
)
SELECT 
    actor_name,
    movie_count,
    first_movie_year,
    last_movie_year,
    (last_movie_year - first_movie_year) AS active_years,
    movies,
    SUM(num_companies) AS total_companies_involved
FROM 
    MovieDetails md
JOIN 
    ActorStats as ON as.actor_name = md.actor_name
GROUP BY 
    actor_name, movie_count, first_movie_year, last_movie_year
ORDER BY 
    movie_count DESC, active_years DESC
LIMIT 10;
