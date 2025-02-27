WITH MovieDetails AS (
    SELECT 
        a.title, 
        a.production_year, 
        c.person_id AS actor_id, 
        ak.name AS actor_name, 
        rk.role AS role_name
    FROM 
        aka_title a
    INNER JOIN 
        complete_cast cc ON a.id = cc.movie_id
    INNER JOIN 
        cast_info c ON cc.subject_id = c.id
    INNER JOIN 
        aka_name ak ON c.person_id = ak.person_id
    INNER JOIN 
        role_type rk ON c.role_id = rk.id
    WHERE 
        a.production_year >= 2000
),
ActorStats AS (
    SELECT 
        actor_id,
        COUNT(DISTINCT title) AS movie_count,
        STRING_AGG(title, ', ') AS movies
    FROM 
        MovieDetails
    GROUP BY 
        actor_id
),
RankedActors AS (
    SELECT 
        actor_id, 
        movie_count, 
        movies,
        RANK() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM 
        ActorStats
)
SELECT 
    ra.actor_id, 
    ak.name AS actor_name,
    ra.movie_count,
    ra.movies,
    ra.actor_rank,
    COALESCE(pi.info, 'No info available') AS personal_info
FROM 
    RankedActors ra
LEFT JOIN 
    aka_name ak ON ra.actor_id = ak.person_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = (
        SELECT 
            id 
        FROM 
            info_type 
        WHERE 
            info = 'Biography'
        LIMIT 1
    )
WHERE 
    ra.actor_rank <= 10
ORDER BY 
    ra.actor_rank;
