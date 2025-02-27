WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        a.id AS actor_id,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.actor_name,
    cd.actor_count,
    CASE 
        WHEN cd.actor_count > 5 THEN 'Large Cast'
        WHEN cd.actor_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END AS cast_size,
    (SELECT AVG(r.actor_count) 
     FROM CastDetails r) AS avg_cast_size,
    COALESCE(cd.actor_name, 'Unnamed Actor') AS displayed_actor_name
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.year_rank <= 10
ORDER BY 
    rm.production_year DESC, cd.actor_count DESC;
