WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER(PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year > 2000
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        p.person_id,
        r.role AS actor_role,
        COUNT(*) OVER(PARTITION BY c.person_id) AS role_count
    FROM 
        cast_info c
    INNER JOIN 
        role_type r ON c.role_id = r.id
    INNER JOIN 
        aka_name p ON c.person_id = p.person_id
    WHERE 
        c.nr_order IS NOT NULL
)
SELECT 
    rm.movie_title,
    rm.production_year,
    STRING_AGG(DISTINCT ar.actor_role, ', ') AS roles,
    COUNT(DISTINCT ar.person_id) AS number_of_actors,
    SUM(CASE WHEN ar.role_count > 1 THEN 1 ELSE 0 END) AS multiple_roles_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_title = ar.movie_id
GROUP BY 
    rm.movie_title, rm.production_year
HAVING 
    COUNT(DISTINCT ar.person_id) > 5
ORDER BY 
    rm.production_year DESC, rm.movie_title;
