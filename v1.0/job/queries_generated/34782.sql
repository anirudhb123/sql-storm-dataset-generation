WITH RECURSIVE ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
),
MovieStats AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) AS actors_with_no_note
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
),
RankedMovies AS (
    SELECT
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.actor_count,
        ms.actors_with_no_note,
        DENSE_RANK() OVER (ORDER BY ms.actor_count DESC) AS rank_by_actor_count,
        CASE 
            WHEN ms.actor_count >= 10 THEN 'High'
            WHEN ms.actor_count BETWEEN 5 AND 9 THEN 'Moderate'
            ELSE 'Low'
        END AS actor_density
    FROM 
        MovieStats ms
)
SELECT 
    am.actor_id,
    am.actor_name,
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.actors_with_no_note,
    rm.rank_by_actor_count,
    rm.actor_density
FROM 
    ActorMovies am
JOIN 
    RankedMovies rm ON am.movie_id = rm.movie_id
WHERE 
    am.movie_rank = 1
    AND (rm.actor_density = 'High' OR rm.actors_with_no_note > 0)
ORDER BY 
    rm.rank_by_actor_count, rm.production_year DESC;
