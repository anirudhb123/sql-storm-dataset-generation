WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(SUM(cast.nr_order), 0) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info cast ON a.id = cast.movie_id
    GROUP BY 
        a.id
),
RecentMovies AS (
    SELECT 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 10
),
ActorStats AS (
    SELECT 
        n.name AS actor_name,
        COUNT(ci.movie_id) AS movies_count,
        AVG(m.production_year) AS avg_year
    FROM 
        name n
    JOIN 
        cast_info ci ON n.id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    WHERE 
        n.md5sum IS NOT NULL
    GROUP BY 
        n.name
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(as.actor_name, 'Unknown Actor') AS actor_name,
    as.movies_count,
    as.avg_year
FROM 
    RecentMovies rm
LEFT JOIN 
    ActorStats as ON rm.production_year = as.avg_year
ORDER BY 
    rm.production_year DESC, rm.title;
