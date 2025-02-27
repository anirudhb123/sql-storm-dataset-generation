WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS role_order
    FROM 
        aka_title t
    INNER JOIN 
        complete_cast cc ON t.id = cc.movie_id
    INNER JOIN 
        cast_info c ON cc.subject_id = c.id
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count
    FROM 
        RankedMovies
    GROUP BY 
        actor_name
),
FilteredActors AS (
    SELECT 
        actor_name 
    FROM 
        ActorCounts
    WHERE 
        movie_count >= 5
)
SELECT 
    m.movie_title,
    m.production_year,
    STRING_AGG(DISTINCT a.actor_name, ', ') AS actors
FROM 
    RankedMovies m
LEFT JOIN 
    FilteredActors fa ON m.actor_name = fa.actor_name
LEFT JOIN 
    aka_title at ON m.movie_title = at.title AND m.production_year = at.production_year
WHERE 
    fa.actor_name IS NOT NULL
GROUP BY 
    m.movie_title, m.production_year
HAVING 
    COUNT(DISTINCT m.actor_name) > 0
ORDER BY 
    m.production_year DESC, m.movie_title;
