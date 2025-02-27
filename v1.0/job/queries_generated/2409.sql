WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorsWithRoles AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ca.movie_id) AS movies_count,
        STRING_AGG(DISTINCT r.role ORDER BY r.role) AS roles
    FROM 
        aka_name a
    JOIN 
        cast_info ca ON a.person_id = ca.person_id
    JOIN 
        role_type r ON ca.role_id = r.id
    GROUP BY 
        a.id, a.name
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    awr.name AS actor_name,
    awr.movies_count,
    awr.roles,
    mwk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsWithRoles awr ON awr.movies_count > 1
LEFT JOIN 
    MoviesWithKeywords mwk ON rm.movie_id = mwk.movie_id
WHERE 
    rm.actor_count_rank <= 5 
    AND (rm.production_year IS NOT NULL AND rm.production_year > 2000)
ORDER BY 
    rm.production_year DESC, awr.movies_count DESC;
