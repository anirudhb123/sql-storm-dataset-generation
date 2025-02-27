
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title AS t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND t.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.role_id) AS role_count
    FROM 
        cast_info AS c
    JOIN 
        RankedMovies AS rm ON c.movie_id = rm.movie_id
    GROUP BY 
        c.person_id
),
TopActors AS (
    SELECT 
        p.id AS actor_id,
        a.name AS actor_name,
        arc.role_count,
        RANK() OVER (ORDER BY arc.role_count DESC) AS actor_rank
    FROM 
        aka_name AS a
    JOIN 
        ActorRoleCounts AS arc ON a.person_id = arc.person_id
    JOIN 
        name AS p ON a.person_id = p.imdb_id
    WHERE 
        arc.role_count IS NOT NULL
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    ta.actor_id,
    ta.actor_name,
    ta.role_count,
    ta.actor_rank
FROM 
    RankedMovies AS tm
LEFT JOIN 
    TopActors AS ta ON tm.movie_id IN (
        SELECT 
            c.movie_id 
        FROM 
            cast_info AS c 
        WHERE 
            c.person_id = ta.actor_id
    )
WHERE 
    tm.title_rank <= 10 AND 
    ta.actor_rank IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    ta.actor_rank
LIMIT 20;
