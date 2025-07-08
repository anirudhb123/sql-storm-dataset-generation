
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCount ac ON rm.movie_id = ac.movie_id
    WHERE 
        rm.rank_per_year <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.actor_count, 0) AS number_of_actors,
    CASE 
        WHEN tm.actor_count IS NULL THEN 'No cast information'
        ELSE 'Has cast information'
    END AS cast_info_status,
    LISTAGG(CONCAT(a.name, ' as ', r.role), ', ') WITHIN GROUP (ORDER BY a.name) AS cast_detail
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
GROUP BY 
    tm.title, tm.production_year, tm.actor_count, tm.movie_id
ORDER BY 
    tm.production_year DESC, number_of_actors DESC;
