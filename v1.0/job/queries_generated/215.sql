WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        t.kind_id, 
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS Rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.name AS ActorName, 
        ct.kind AS RoleType, 
        COUNT(ci.movie_id) AS MovieCount
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type ct ON ci.role_id = ct.id
    GROUP BY 
        a.name, ct.kind
    HAVING 
        COUNT(ci.movie_id) > 5
)
SELECT 
    rm.title AS MovieTitle, 
    rm.production_year, 
    ar.ActorName, 
    ar.RoleType, 
    ar.MovieCount,
    COALESCE(mi.info, 'No additional info') AS MovieInfo
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.id = cc.movie_id
LEFT JOIN 
    ActorRoles ar ON cc.subject_id = (SELECT person_id FROM aka_name WHERE name = ar.ActorName LIMIT 1)
LEFT JOIN 
    movie_info mi ON rm.kind_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary' LIMIT 1)
WHERE 
    rm.Rank <= 10 AND 
    (ar.RoleType IS NOT NULL OR ar.MovieCount > 0)
ORDER BY 
    rm.production_year DESC, ar.MovieCount DESC, ar.ActorName;
