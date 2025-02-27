WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title, 
        t.production_year, 
        a.name AS actor_name, 
        r.role AS role_name, 
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
),
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        k.keyword
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
)
SELECT 
    rm.movie_title, 
    rm.production_year, 
    rm.actor_name, 
    rm.role_name, 
    STRING_AGG(mk.keyword, ', ') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.rn = 1
GROUP BY 
    rm.movie_title, rm.production_year, rm.actor_name, rm.role_name
ORDER BY 
    rm.production_year DESC, rm.movie_title;
