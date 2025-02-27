WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.person_id,
        c.role_id,
        a.name, 
        COUNT(DISTINCT cm.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        complete_cast cm ON c.movie_id = cm.movie_id
    GROUP BY 
        a.person_id, c.role_id, a.name
),
TopActors AS (
    SELECT 
        ra.movie_id,
        ar.name AS actor_name,
        ar.movie_count
    FROM 
        RankedMovies ra
    JOIN 
        ActorRoles ar ON ra.movie_id = ar.movie_id
    WHERE 
        ar.movie_count > 5
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    ta.actor_name,
    COALESCE(ki.keyword, 'No Keywords') AS keyword_info
FROM 
    TopActors ta
JOIN 
    aka_title t ON ta.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, movie_title,
    CASE WHEN ta.actor_name IS NULL THEN 1 ELSE 0 END, 
    ta.actor_name;
