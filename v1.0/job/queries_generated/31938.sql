WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        CONCAT(a.name, ' (', ct.kind, ')') AS actor_role,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ci.nr_order = 1  -- starting from the primary actor

    UNION ALL

    SELECT 
        ci.person_id,
        CONCAT(a.name, ' (', ct.kind, ')') AS actor_role,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    JOIN 
        ActorHierarchy ah ON ci.movie_id = (
            SELECT 
                movie_id 
            FROM 
                complete_cast cc
            WHERE 
                cc.subject_id = ah.person_id
            LIMIT 1
        )
    WHERE 
        ci.nr_order > 1  -- iterating for supporting actors
),
TotalMovieCounts AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors
    FROM 
        title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id
),
ActorMovies AS (
    SELECT 
        ah.person_id,
        t.title,
        t.id AS movie_id,
        COALESCE(tm.total_actors, 0) AS total_actors
    FROM 
        ActorHierarchy ah
    JOIN 
        cast_info ci ON ah.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    LEFT JOIN 
        TotalMovieCounts tm ON tm.movie_id = t.id
),
TopActors AS (
    SELECT 
        person_id,
        COUNT(*) AS movie_count
    FROM 
        ActorMovies
    GROUP BY 
        person_id
    HAVING 
        COUNT(*) > 5 -- Actors who have worked in more than 5 movies
)
SELECT 
    a.name,
    ta.movie_count,
    STRING_AGG(DISTINCT am.title, ', ') AS movies,
    MAX(am.total_actors) AS max_cast_size
FROM 
    TopActors ta
JOIN 
    aka_name a ON ta.person_id = a.person_id
JOIN 
    ActorMovies am ON am.person_id = ta.person_id
GROUP BY 
    a.name, ta.movie_count
ORDER BY 
    ta.movie_count DESC;
