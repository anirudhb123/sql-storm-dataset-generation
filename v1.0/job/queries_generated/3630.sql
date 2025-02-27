WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorStats AS (
    SELECT 
        co.name AS company_name,
        COUNT(DISTINCT cc.movie_id) AS total_movies,
        AVG(a.production_year) AS avg_production_year
    FROM 
        company_name co
    JOIN 
        movie_companies mc ON co.id = mc.company_id
    JOIN 
        complete_cast cc ON mc.movie_id = cc.movie_id
    JOIN 
        title a ON cc.movie_id = a.id
    GROUP BY 
        co.name
),
PopularActors AS (
    SELECT 
        ak.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
    HAVING 
        COUNT(ci.movie_id) > 5
)
SELECT 
    rm.title,
    rm.production_year,
    as.company_name,
    pa.name AS popular_actor,
    pa.movie_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorStats as ON rm.year_rank <= 5
LEFT JOIN 
    PopularActors pa ON pa.movie_count >= 2
WHERE 
    (as.avg_production_year IS NULL OR rm.production_year > as.avg_production_year)
ORDER BY 
    rm.production_year DESC, as.company_name, pa.movie_count DESC
LIMIT 100;
