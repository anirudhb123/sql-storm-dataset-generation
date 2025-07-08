
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (
            SELECT id FROM kind_type WHERE kind IN ('movie', 'feature')
        )
),
ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        t.title,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.name, t.title, r.role
),
KeywordStats AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_name,
    ks.keywords,
    ar.role_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.title = ar.title
LEFT JOIN 
    KeywordStats ks ON rm.movie_id = ks.movie_id
WHERE 
    rm.year_rank <= 5
    AND (ks.keywords IS NOT NULL OR ar.role_count > 2)
ORDER BY 
    rm.production_year DESC, ar.role_count DESC;
