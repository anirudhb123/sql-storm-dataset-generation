
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM title t
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE t.production_year > 2000
    GROUP BY t.id, t.title, t.production_year
),
MovieInfos AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS movie_details
    FROM movie_info mi
    JOIN RankedMovies rm ON mi.movie_id = rm.movie_id
    GROUP BY mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.actor_names,
    COALESCE(mi.movie_details, 'No details available') AS movie_details
FROM RankedMovies rm
LEFT JOIN MovieInfos mi ON rm.movie_id = mi.movie_id
ORDER BY rm.production_year DESC, rm.actor_count DESC
LIMIT 100;
