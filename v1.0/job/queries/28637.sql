WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        r.role AS actor_role,
        a.name AS actor_name,
        p.info AS actor_info
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        t.production_year >= 2000
        AND c.country_code = 'USA'
),

CompanyMovieCount AS (
    SELECT 
        company_name,
        COUNT(movie_title) AS movie_count
    FROM 
        MovieDetails
    GROUP BY 
        company_name
),

ActorCount AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS acting_roles
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
   HAVING
        COUNT(DISTINCT movie_title) > 5
)

SELECT 
    md.movie_title,
    md.production_year,
    cm.movie_count AS total_movies_by_company,
    ac.actor_name,
    ac.acting_roles
FROM 
    MovieDetails md
JOIN 
    CompanyMovieCount cm ON md.company_name = cm.company_name
JOIN 
    ActorCount ac ON md.actor_name = ac.actor_name
ORDER BY 
    md.production_year DESC, 
    cm.movie_count DESC, 
    ac.acting_roles DESC;
