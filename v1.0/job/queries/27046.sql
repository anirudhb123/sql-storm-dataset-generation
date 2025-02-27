WITH RankedActors AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2009
    GROUP BY 
        a.id, a.name
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        r.role AS actor_role,
        c.movie_id
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
)

SELECT 
    ra.actor_name,
    ra.movie_count,
    mc.company_name,
    mc.company_type,
    ar.actor_role
FROM 
    RankedActors ra
JOIN 
    ActorRoles ar ON ra.actor_name = ar.actor_name
JOIN 
    MovieCompanies mc ON ar.movie_id = mc.movie_id
ORDER BY 
    ra.movie_count DESC, mc.company_name;