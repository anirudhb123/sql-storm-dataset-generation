WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.episode_of_id,
        1 AS depth
    FROM 
        title m
    WHERE 
        m.episode_of_id IS NULL  
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.episode_of_id,
        mh.depth + 1
    FROM 
        title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id  
),
ActorMovieCounts AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name ca ON c.person_id = ca.person_id
    GROUP BY 
        ca.person_id
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        amc.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCounts amc ON a.person_id = amc.person_id
    WHERE 
        amc.movie_count > 5 
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COALESCE(t.name, 'No Actor') AS lead_actor,
    mk.keywords,
    mh.depth,
    COALESCE(amc.movie_count, 0) AS actor_movies_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TopActors t ON mh.movie_id = (SELECT c.movie_id 
                                    FROM cast_info c 
                                    WHERE c.person_id = t.person_id 
                                    ORDER BY c.nr_order 
                                    LIMIT 1) 
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    ActorMovieCounts amc ON t.person_id = amc.person_id
WHERE 
    mh.depth = 1 
ORDER BY 
    mh.production_year DESC, 
    mh.movie_title;