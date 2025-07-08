
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM title m
    JOIN cast_info ci ON m.id = ci.movie_id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE m.production_year IS NOT NULL
    GROUP BY m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.actors
    FROM RankedMovies rm
    WHERE rm.rank <= 5  
)
SELECT 
    tm.production_year,
    LISTAGG(tm.title, '; ') WITHIN GROUP (ORDER BY tm.title) AS top_movies,
    SUM(tm.actor_count) AS total_actors,
    LISTAGG(tm.actors, '; ') WITHIN GROUP (ORDER BY tm.actors) AS all_actors
FROM TopMovies tm
GROUP BY tm.production_year
ORDER BY tm.production_year DESC;
