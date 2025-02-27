
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.actor_count, 0) AS total_actors
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.total_actors,
    CASE 
        WHEN fm.total_actors = 0 THEN 'No Actors'
        WHEN fm.total_actors IS NULL THEN 'Unknown'
        ELSE 'Total Actors: ' || CAST(fm.total_actors AS VARCHAR)
    END AS actor_status,
    (
        SELECT 
            STRING_AGG(DISTINCT cn.name, ', ') 
        FROM 
            company_name cn 
        JOIN 
            movie_companies mc ON cn.id = mc.company_id 
        WHERE 
            mc.movie_id = fm.movie_id
    ) AS production_companies
FROM 
    FilteredMovies fm
GROUP BY 
    fm.movie_id, 
    fm.title, 
    fm.production_year, 
    fm.total_actors
ORDER BY 
    fm.production_year DESC, 
    fm.total_actors DESC;
