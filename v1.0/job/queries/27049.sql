WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        a.name AS actor_name,
        r.role AS actor_role
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND LOWER(t.title) LIKE '%adventure%'
),
AggregateActorRoles AS (
    SELECT 
        actor_name,
        COUNT(actor_role) AS role_count,
        STRING_AGG(DISTINCT actor_role, ', ') AS roles
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
    HAVING 
        COUNT(actor_role) > 1
),
TopActors AS (
    SELECT 
        actor_name,
        role_count,
        roles,
        ROW_NUMBER() OVER (ORDER BY role_count DESC) AS rank
    FROM 
        AggregateActorRoles
)
SELECT 
    actor_name,
    role_count,
    roles
FROM 
    TopActors
WHERE 
    rank <= 10;