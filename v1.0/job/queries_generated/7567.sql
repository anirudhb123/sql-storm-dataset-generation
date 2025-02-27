WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        r.role,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
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
), ActorCounts AS (
    SELECT 
        actor_name,
        COUNT(*) AS movie_count
    FROM 
        RankedMovies
    WHERE 
        rank = 1
    GROUP BY 
        actor_name
    HAVING 
        COUNT(*) > 5
), MoviesWithKeywords AS (
    SELECT 
        t.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title
)
SELECT 
    ac.actor_name,
    ac.movie_count,
    mwk.title,
    mwk.keywords
FROM 
    ActorCounts ac
JOIN 
    RankedMovies rm ON ac.actor_name = rm.actor_name
JOIN 
    MoviesWithKeywords mwk ON rm.title = mwk.title
ORDER BY 
    ac.movie_count DESC, 
    mwk.title;
