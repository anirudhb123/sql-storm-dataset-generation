WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        1 AS level
    FROM 
        cast_info c
    WHERE 
        c.nr_order = 1  -- Starting with lead actors

    UNION ALL

    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        ActorHierarchy ah ON c.movie_id = ah.movie_id
    WHERE 
        c.nr_order > ah.level
),

MovieWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),

ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ah.movie_id) AS total_movies,
        SUM(CASE WHEN ah.level > 1 THEN 1 ELSE 0 END) AS supporting_roles
    FROM 
        aka_name a
    LEFT JOIN 
        ActorHierarchy ah ON a.person_id = ah.person_id
    GROUP BY 
        a.id
),

FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        COALESCE(ai.total_movies, 0) AS total_actors,
        COALESCE(ai.supporting_roles, 0) AS supporting_roles,
        CASE 
            WHEN ai.total_movies IS NULL THEN 'No Actors'
            ELSE 'Has Actors'
        END AS actor_status
    FROM 
        MovieWithKeywords m
    LEFT JOIN 
        ActorInfo ai ON m.movie_id = ai.actor_id
    WHERE 
        (m.movie_title ILIKE '%action%' OR m.movie_title ILIKE '%drama%')
        AND m.movie_title IS NOT NULL
)

SELECT 
    fm.movie_title,
    fm.total_actors,
    fm.supporting_roles,
    fm.actor_status,
    COALESCE(ai.actor_name, 'Unknown') AS lead_actor
FROM 
    FilteredMovies fm
LEFT JOIN 
    cast_info c ON fm.movie_id = c.movie_id AND c.nr_order = 1
LEFT JOIN 
    aka_name ai ON c.person_id = ai.person_id
ORDER BY 
    fm.supporting_roles DESC, 
    fm.total_actors DESC;
