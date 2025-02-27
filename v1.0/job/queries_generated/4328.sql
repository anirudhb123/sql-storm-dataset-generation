WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        actor_id,
        COUNT(*) AS movie_count
    FROM 
        RankedMovies
    GROUP BY 
        actor_id
    HAVING 
        COUNT(*) > 3
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    a.actor_name,
    ARRAY_AGG(DISTINCT m.title) AS movies,
    ac.movie_count,
    STRING_AGG(DISTINCT kw.keyword) AS keywords,
    MAX(CASE WHEN mw.keyword_rank = 1 THEN k.keyword END) AS primary_keyword
FROM 
    ActorCounts ac
JOIN 
    RankedMovies a ON ac.actor_id = a.actor_id
LEFT JOIN 
    MoviesWithKeywords mw ON a.movie_title = mw.title
LEFT JOIN 
    keyword k ON mw.keyword_id = k.id
GROUP BY 
    a.actor_name, ac.movie_count
ORDER BY 
    ac.movie_count DESC, a.actor_name;
