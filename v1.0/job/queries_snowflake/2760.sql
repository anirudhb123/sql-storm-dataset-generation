
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        LISTAGG(m.info, ', ') AS info_details
    FROM movie_info m
    GROUP BY m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    mi.info_details,
    CASE
        WHEN rm.rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS movie_ranking
FROM RankedMovies rm
LEFT JOIN ActorCounts ac ON rm.movie_id = ac.movie_id
LEFT JOIN MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE rm.production_year > 2000
GROUP BY 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    ac.actor_count, 
    mi.info_details, 
    rm.rank
ORDER BY rm.production_year DESC, rm.title ASC;
