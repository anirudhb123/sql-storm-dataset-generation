WITH MovieStats AS (
    SELECT 
        t.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(mi.info_length) AS avg_info_length
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    LEFT JOIN 
        (SELECT 
            movie_id,
            LENGTH(info) AS info_length
         FROM 
            movie_info) mi ON mi.movie_id = t.id
    GROUP BY 
        t.title
),
ActorStats AS (
    SELECT
        a.name AS actor_name,
        COUNT(DISTINCT cc.movie_id) AS movies_count,
        SUM(CASE WHEN cc.note IS NOT NULL THEN 1 ELSE 0 END) AS with_notes_count
    FROM 
        aka_name a
    JOIN 
        cast_info cc ON a.person_id = cc.person_id
    GROUP BY 
        a.name
),
HighMovieStats AS (
    SELECT 
        movie_title,
        actor_count,
        avg_info_length
    FROM 
        MovieStats
    WHERE 
        actor_count > 5 AND avg_info_length > 100
)
SELECT 
    hms.movie_title,
    ast.actor_name,
    ast.movies_count,
    ast.with_notes_count
FROM 
    HighMovieStats hms
JOIN 
    ActorStats ast ON ast.movies_count > 2
ORDER BY 
    hms.actor_count DESC, 
    ast.movies_count ASC
LIMIT 10;


