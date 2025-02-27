WITH RankedCast AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
TopRankedMovies AS (
    SELECT 
        rc.movie_id,
        t.title,
        t.production_year,
        COUNT(rc.actor_name) AS actor_count
    FROM 
        RankedCast rc
    JOIN 
        title t ON rc.movie_id = t.id
    WHERE 
        rc.rank <= 3
    GROUP BY 
        rc.movie_id, t.title, t.production_year
)
SELECT 
    t.title,
    t.production_year,
    tm.actor_count,
    GROUP_CONCAT(DISTINCT rc.actor_name) AS top_actors
FROM 
    TopRankedMovies tm
JOIN 
    RankedCast rc ON tm.movie_id = rc.movie_id
GROUP BY 
    t.title, 
    t.production_year, 
    tm.actor_count
ORDER BY 
    tm.actor_count DESC, 
    t.production_year ASC;
