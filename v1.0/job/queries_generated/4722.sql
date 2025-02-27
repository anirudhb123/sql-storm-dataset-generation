WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieActors AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        COUNT(c.person_id) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
),
PopularMovies AS (
    SELECT 
        mv.title,
        mv.production_year,
        mai.actor_name,
        mai.total_cast,
        ROW_NUMBER() OVER (PARTITION BY mv.production_year ORDER BY mai.total_cast DESC) AS actor_rank
    FROM 
        RankedMovies mv
    LEFT JOIN 
        MovieActors mai ON mv.id = mai.movie_id 
)
SELECT 
    pm.title,
    pm.production_year,
    COALESCE(pm.actor_name, 'No actors') AS actor_name,
    pm.total_cast,
    CASE 
        WHEN pm.total_cast > 10 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity_status
FROM 
    PopularMovies pm
WHERE 
    pm.rn <= 5 AND pm.actor_rank <= 3
ORDER BY 
    pm.production_year ASC, 
    pm.total_cast DESC;
