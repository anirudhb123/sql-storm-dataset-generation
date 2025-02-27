WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorStats AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        COALESCE(mi.info, 'No info available') AS movie_info,
        ki.keyword AS keyword
    FROM 
        movie_info m
    LEFT JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id AND mi.note IS NULL
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(as.actor_count, 0) AS actor_count,
    as.actor_names,
    COALESCE(mi.movie_info, 'N/A') AS movie_info,
    COUNT(*) OVER (PARTITION BY rm.production_year) AS movies_in_year
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorStats as ON rm.movie_id = as.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.title;
