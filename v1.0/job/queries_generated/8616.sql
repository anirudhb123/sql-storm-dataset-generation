WITH ActorTitles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS production_year,
        c.kind AS company_role
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind = 'Production'
),
ActorRoles AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count,
        ARRAY_AGG(DISTINCT movie_title) AS movies
    FROM 
        ActorTitles
    GROUP BY 
        actor_id, actor_name
)
SELECT 
    ar.actor_id,
    ar.actor_name,
    ar.movie_count,
    unnest(ar.movies) AS individual_movies
FROM 
    ActorRoles ar
ORDER BY 
    ar.movie_count DESC
LIMIT 10;
