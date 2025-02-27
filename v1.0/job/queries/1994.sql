WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.num_actors
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
ActorInfo AS (
    SELECT
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY
        ak.id, ak.name
),
HighestRatedActors AS (
    SELECT 
        ai.actor_name,
        ai.movie_count,
        RANK() OVER (ORDER BY ai.movie_count DESC) AS actor_rank
    FROM 
        ActorInfo ai
    WHERE 
        ai.movie_count > 1
)
SELECT 
    fm.title,
    fm.production_year,
    fm.num_actors,
    ha.actor_name,
    ha.movie_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    HighestRatedActors ha ON fm.num_actors = ha.movie_count
WHERE 
    ha.actor_rank IS NULL OR ha.movie_count >= 3
ORDER BY 
    fm.production_year DESC, fm.num_actors DESC;
