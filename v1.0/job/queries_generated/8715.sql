WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.id AS company_id,
        comp.name AS company_name,
        r.role,
        ak.name AS actor_name
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name comp ON mc.company_id = comp.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND comp.country_code = 'USA'
),
ActorStats AS (
    SELECT 
        ak.actor_name,
        COUNT(DISTINCT md.movie_id) AS movie_count,
        STRING_AGG(DISTINCT md.title, ', ') AS movie_titles
    FROM 
        MovieDetails md
    GROUP BY 
        ak.actor_name
)
SELECT 
    actor_name,
    movie_count,
    movie_titles
FROM 
    ActorStats
WHERE 
    movie_count > 5
ORDER BY 
    movie_count DESC;
