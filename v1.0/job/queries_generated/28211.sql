WITH RankedActors AS (
    SELECT 
        ka.person_id, 
        ka.name AS actor_name, 
        ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY c.nr_order) AS actor_rank,
        string_agg(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name ka
    JOIN 
        cast_info c ON ka.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        ka.person_id, ka.name
), 
ActorAwards AS (
    SELECT 
        p.person_id, 
        string_agg(DISTINCT a.info, ', ') AS awards
    FROM 
        person_info p
    JOIN 
        info_type it ON p.info_type_id = it.id
    WHERE 
        it.info ILIKE '%award%'
    GROUP BY 
        p.person_id
), 
TopMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count 
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 3
    ORDER BY 
        actor_count DESC
    LIMIT 10
)

SELECT 
    ra.actor_name, 
    ra.movie_titles, 
    aa.awards, 
    tm.title AS top_movie, 
    tm.production_year 
FROM 
    RankedActors ra
LEFT JOIN 
    ActorAwards aa ON ra.person_id = aa.person_id
LEFT JOIN 
    TopMovies tm ON tm.actor_count = (SELECT MAX(actor_count) FROM TopMovies)
ORDER BY 
    ra.actor_rank;
