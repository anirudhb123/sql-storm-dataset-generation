
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
ActorCount AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT ki.keyword, ', ') WITHIN GROUP (ORDER BY ki.keyword) AS keywords,
        mi.info AS additional_info
    FROM 
        movie_keyword mk
    JOIN 
        keyword ki ON mk.keyword_id = ki.id
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    GROUP BY 
        mk.movie_id, mi.info
)
SELECT 
    rm.title,
    rm.production_year,
    ac.actor_count,
    mi.keywords,
    mi.additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    (rm.year_rank <= 5 AND ac.actor_count IS NOT NULL) 
    OR mi.additional_info IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    ac.actor_count DESC;
