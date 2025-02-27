WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS movie_keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = mt.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    WHERE 
        mt.production_year IS NOT NULL 
        AND ak.name IS NOT NULL
    GROUP BY 
        mt.id
),

AverageActorCount AS (
    SELECT 
        AVG(actor_count) AS avg_actor_count 
    FROM 
        MovieDetails
),

RecentMovies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC) AS rn
    FROM 
        MovieDetails md
    WHERE 
        md.production_year > 2000
),

TopMovies AS (
    SELECT 
        *
    FROM 
        RecentMovies
    WHERE 
        rn <= 5
)

SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.actor_names,
    COALESCE(kw.keywords, 'No keywords') AS keywords,
    COALESCE(ac.avg_actor_count, 0) AS global_average_actor_count
FROM 
    TopMovies tm
LEFT JOIN 
    (SELECT STRING_AGG(keyword, ', ') AS keywords FROM keyword) kw ON TRUE
CROSS JOIN 
    AverageActorCount ac
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
