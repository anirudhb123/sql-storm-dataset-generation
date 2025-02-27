WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        r.role,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.id, a.name, r.role
    HAVING 
        COUNT(c.movie_id) > 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        ARRAY_AGG(k.keyword) AS keywords_list
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ar.name AS actor_name,
    ar.role AS actor_role,
    COALESCE(mk.keywords_list, '{}') AS keywords
FROM 
    RankedMovies rm
JOIN 
    cast_info c ON rm.movie_id = c.movie_id
JOIN 
    ActorRoles ar ON c.person_id = ar.actor_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.title_rank <= 5
    AND ar.movie_count >= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
