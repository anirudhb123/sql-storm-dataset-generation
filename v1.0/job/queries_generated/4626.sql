WITH RankedTitles AS (
    SELECT 
        at.title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS YearRank
    FROM 
        aka_title at 
    WHERE 
        at.production_year IS NOT NULL
),
TopTitles AS (
    SELECT 
        rt.title, 
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.YearRank <= 5
),
PersonMovieRoles AS (
    SELECT 
        c.person_id, 
        c.movie_id, 
        r.role, 
        COUNT(*) OVER (PARTITION BY c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
),
AggregatedRoles AS (
    SELECT 
        pm.person_id, 
        STRING_AGG(pm.role, ', ') AS roles, 
        MAX(pm.role_count) AS total_roles
    FROM 
        PersonMovieRoles pm
    GROUP BY 
        pm.person_id
)
SELECT 
    p.id AS person_id, 
    a.name AS actor_name, 
    COALESCE(ar.roles, 'No Roles Assigned') AS roles_assigned, 
    COALESCE(ar.total_roles, 0) AS roles_total, 
    tt.title AS top_title
FROM 
    aka_name a
LEFT JOIN 
    AggregatedRoles ar ON a.person_id = ar.person_id
LEFT JOIN 
    (SELECT 
        DISTINCT title, 
        production_year 
    FROM 
        TopTitles) tt ON EXISTS (
        SELECT 1 
        FROM cast_info c 
        JOIN aka_title at ON c.movie_id = at.id 
        WHERE c.person_id = a.person_id AND at.title = tt.title
    )
WHERE 
    a.name IS NOT NULL
ORDER BY 
    a.name, tt.production_year DESC;
