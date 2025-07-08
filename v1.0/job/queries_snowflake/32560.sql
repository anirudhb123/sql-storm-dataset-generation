
WITH MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        t.id,
        t.title,
        t.production_year,
        mh.depth + 1
    FROM 
        aka_title t
    JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_actors,
        MIN(r.role) AS lead_role
    FROM 
        cast_info c
    JOIN 
        role_type r ON r.id = c.role_id
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.name) AS total_companies,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON co.id = mc.company_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ar.total_actors, 0) AS total_actors,
    ar.lead_role,
    COALESCE(ci.total_companies, 0) AS total_companies,
    ci.company_names,
    ROW_NUMBER() OVER (ORDER BY mh.production_year DESC) AS rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorRoles ar ON mh.movie_id = ar.movie_id
LEFT JOIN 
    CompanyInfo ci ON mh.movie_id = ci.movie_id
WHERE 
    mh.depth = 1
ORDER BY 
    mh.production_year DESC, rank
LIMIT 50;
