WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        a.name AS actor_name
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name a ON cc.subject_id = a.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword LIKE '%action%'
),
ActorRole AS (
    SELECT 
        a.actor_name,
        rt.role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    WHERE 
        a.person_id IN (SELECT DISTINCT subject_id FROM complete_cast)
    GROUP BY 
        a.actor_name, rt.role
),
TopActors AS (
    SELECT 
        actor_name,
        SUM(role_count) AS total_roles
    FROM 
        ActorRole
    GROUP BY 
        actor_name
    ORDER BY 
        total_roles DESC
    LIMIT 10
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    GROUP_CONCAT(DISTINCT md.keyword) AS keywords,
    ta.actor_name,
    ta.total_roles
FROM 
    MovieDetails md
JOIN 
    TopActors ta ON md.actor_name = ta.actor_name
GROUP BY 
    md.title, md.production_year, md.company_name, ta.actor_name, ta.total_roles
ORDER BY 
    md.production_year DESC, ta.total_roles DESC;
