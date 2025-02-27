
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.person_id,
        a.name,
        COALESCE(ri.role, 'Unknown Role') AS role,
        COUNT(c.movie_id) AS movie_count
    FROM
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        role_type ri ON c.role_id = ri.id
    GROUP BY 
        a.person_id, a.name, ri.role
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    a.name AS actor_name,
    a.role,
    a.movie_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    RankedMovies r
LEFT JOIN 
    ActorRoles a ON a.movie_count > 10 AND EXISTS (
        SELECT 1 FROM cast_info ci WHERE ci.movie_id = r.movie_id AND ci.person_id = a.person_id
    )
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = r.movie_id
WHERE 
    r.title_rank = 1
ORDER BY
    r.production_year DESC,
    r.title ASC
LIMIT 100;
