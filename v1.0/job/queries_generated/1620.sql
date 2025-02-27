WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
)
SELECT 
    rt.title,
    rt.production_year,
    ar.actor_name,
    ar.role_name,
    COALESCE(ar.role_rank, 0) AS role_rank,
    CASE 
        WHEN rt.title_rank = 1 THEN 'First Title of Year'
        ELSE 'Subsequent Title of Year'
    END AS title_status
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoles ar ON rt.title_id = c.movie_id
LEFT JOIN 
    movie_info mi ON rt.title_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary' LIMIT 1)
WHERE 
    rt.title IS NOT NULL
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC, 
    ar.role_rank ASC;
