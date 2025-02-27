WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY YEAR(t.production_year) ORDER BY t.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS movie_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
NullSensitiveData AS (
    SELECT 
        t.production_year,
        COALESCE(am.actor_count, 0) AS actor_count,
        CASE 
            WHEN am.actor_count IS NULL THEN 'Uncast'
            WHEN am.actor_count > 5 THEN 'Star-studded'
            ELSE 'Moderate'
        END AS cast_quality
    FROM 
        RankedMovies t
    LEFT JOIN 
        ActorMovies am ON t.movie_id = am.movie_id
)
SELECT 
    r.title,
    r.production_year,
    r.movie_count,
    ns.actor_count,
    ns.cast_quality,
    (CASE 
        WHEN ns.actor_count IS NULL 
            THEN 'No actors available'
        WHEN ns.actor_count = 0 
            THEN 'No cast at all'
        ELSE 'Cast present'
    END) AS cast_presence_status
FROM 
    RankedMovies r
JOIN 
    NullSensitiveData ns ON r.production_year = ns.production_year
WHERE 
    r.rn <= 5
ORDER BY 
    r.production_year DESC, 
    r.movie_count DESC;
