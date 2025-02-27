WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
    HAVING 
        COUNT(c.id) > 1
),
CompanyMovements AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        MAX(CASE WHEN ct.kind = 'Distributor' THEN 'Yes' ELSE 'No' END) AS has_distributor
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword,
    ar.actor_name,
    ar.role_name,
    cm.company_count,
    cm.has_distributor
FROM 
    MovieDetails md
LEFT JOIN 
    ActorRoles ar ON md.movie_id = ar.movie_id
LEFT JOIN 
    CompanyMovements cm ON md.movie_id = cm.movie_id
WHERE 
    (ar.role_name IS NOT NULL AND ar.role_count > 1)
    OR (cm.company_count > 0 AND cm.has_distributor = 'Yes')
ORDER BY 
    md.production_year DESC, 
    md.title;
