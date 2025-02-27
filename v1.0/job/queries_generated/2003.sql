WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_role_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_role_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopActors AS (
    SELECT 
        a.name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(c.movie_id) > 5
),
MovieKeywords AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    ta.name AS top_actor,
    ta.movie_count,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON rm.actor_count > 10
LEFT JOIN 
    MovieKeywords mk ON rm.id = mk.movie_id
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
