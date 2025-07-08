
WITH MovieActors AS (
    SELECT 
        a.name AS actor_name,
        a.person_id,
        m.title AS movie_title,
        m.production_year,
        c.nr_order AS role_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
),
ActorCount AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count
    FROM 
        MovieActors
    GROUP BY 
        actor_name
),
TopActors AS (
    SELECT 
        actor_name,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        ActorCount
    WHERE 
        movie_count > 1
)
SELECT 
    t.actor_name,
    t.movie_count,
    LISTAGG(m.movie_title, ', ') AS movie_titles
FROM 
    TopActors t
JOIN 
    MovieActors m ON t.actor_name = m.actor_name
WHERE 
    t.rank <= 10
GROUP BY 
    t.actor_name, t.movie_count
ORDER BY 
    t.movie_count DESC;
