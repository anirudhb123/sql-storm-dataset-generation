WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonRoleCounts AS (
    SELECT 
        ci.person_id,
        ci.role_id,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id, ci.role_id
),
TopRoles AS (
    SELECT 
        prc.person_id,
        r.role,
        prc.role_count,
        RANK() OVER (PARTITION BY prc.person_id ORDER BY prc.role_count DESC) AS role_rank
    FROM 
        PersonRoleCounts prc
    JOIN 
        role_type r ON prc.role_id = r.id
)
SELECT 
    pm.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    tr.role AS top_role,
    tr.role_count
FROM 
    aka_name pm
JOIN 
    cast_info ci ON pm.person_id = ci.person_id
JOIN 
    RankedMovies rm ON ci.movie_id = rm.movie_id
JOIN 
    TopRoles tr ON ci.person_id = tr.person_id
WHERE 
    rm.rank = 1 
    AND tr.role_rank = 1
ORDER BY 
    rm.production_year DESC, pm.name;
