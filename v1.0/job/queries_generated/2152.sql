WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        k.keyword, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a 
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
    WHERE 
        a.production_year IS NOT NULL
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
SelectedMovies AS (
    SELECT 
        rm.title, 
        rm.production_year,
        ac.actor_count,
        CASE 
            WHEN ac.actor_count > 5 THEN 'Large Cast'
            WHEN ac.actor_count BETWEEN 3 AND 5 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM 
        RankedMovies rm
    INNER JOIN 
        ActorCounts ac ON rm.title = ac.movie_id 
    WHERE 
        rm.year_rank <= 10
),
AggregateInfo AS (
    SELECT 
        sm.production_year,
        COUNT(*) AS total_movies,
        AVG(sm.actor_count) AS avg_actor_count,
        MAX(sm.actor_count) AS max_actor_count
    FROM 
        SelectedMovies sm
    GROUP BY 
        sm.production_year
)
SELECT 
    ai.production_year,
    ai.total_movies,
    ai.avg_actor_count,
    ai.max_actor_count,
    CASE 
        WHEN ai.total_movies > 0 THEN 'Data Available'
        ELSE 'No Data'
    END AS data_status
FROM 
    AggregateInfo ai
ORDER BY 
    ai.production_year DESC;
