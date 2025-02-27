WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv movie'))
),
ActorMovieCount AS (
    SELECT 
        actor_id,
        COUNT(*) AS movie_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
    GROUP BY 
        actor_id
),
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM 
        ActorMovieCount
)
SELECT 
    a.actor_name,
    a.movie_count,
    m.title,
    m.production_year,
    COALESCE(m.image_url, 'No image available') AS image_url,
    (
        SELECT 
            GROUP_CONCAT(DISTINCT g.genre ORDER BY g.genre) 
        FROM 
            movie_genre g 
        WHERE 
            g.movie_id = m.movie_id
    ) AS genres
FROM 
    TopActors a
JOIN 
    RankedMovies m ON a.actor_id = m.actor_id
WHERE 
    a.actor_rank <= 5
ORDER BY 
    a.movie_count DESC, m.production_year DESC;
