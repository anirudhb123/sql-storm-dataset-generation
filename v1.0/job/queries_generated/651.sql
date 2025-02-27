WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        ct.kind AS role_type,
        COUNT(*) OVER (PARTITION BY a.id ORDER BY ct.kind) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    JOIN 
        role_type ct ON ci.role_id = ct.id
    WHERE 
        a.name IS NOT NULL
)
SELECT 
    r.production_year,
    r.movie_title,
    r.cast_count,
    STRING_AGG(DISTINCT ar.actor_name || ' (' || ar.role_type || ')', ', ') AS actors,
    CASE 
        WHEN r.cast_count = 0 THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_presence
FROM 
    RankedMovies r
LEFT JOIN 
    ActorRoles ar ON r.movie_title = ar.movie_title
WHERE 
    r.rn <= 5
GROUP BY 
    r.production_year, r.movie_title, r.cast_count
ORDER BY 
    r.production_year DESC, r.cast_count DESC;
