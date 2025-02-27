WITH MovieWithCompanyInfo AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        c.name AS company_name,
        cc.kind AS company_type,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.name) AS company_order
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type cc ON mc.company_type_id = cc.id
    WHERE 
        a.production_year IS NOT NULL
),

ActorRoles AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', rt.role, ')'), ', ') AS actor_list
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.company_name,
    m.company_type,
    COALESCE(ar.total_actors, 0) AS total_actors,
    COALESCE(ar.actor_list, 'No actors listed') AS actor_list
FROM 
    MovieWithCompanyInfo m
LEFT JOIN 
    ActorRoles ar ON m.movie_id = ar.movie_id
WHERE 
    m.company_order = 1
ORDER BY 
    m.production_year DESC, 
    m.title;
