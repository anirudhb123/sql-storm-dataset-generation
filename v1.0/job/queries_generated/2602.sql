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
ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
),
MovieStats AS (
    SELECT 
        am.actor_id,
        am.actor_name,
        COUNT(am.movie_id) AS movie_count,
        AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, am.production_year))) AS average_movie_age
    FROM 
        ActorMovies am
    GROUP BY 
        am.actor_id, am.actor_name
)
SELECT 
    ms.actor_id,
    ms.actor_name,
    ms.movie_count,
    CASE 
        WHEN ms.average_movie_age IS NULL THEN 'UNKNOWN'
        ELSE TO_CHAR(ms.average_movie_age, '999.99')
    END AS average_movie_age,
    COALESCE(mk.keyword_count, 0) AS keyword_count
FROM 
    MovieStats ms
LEFT JOIN (
    SELECT 
        movie_id,
        COUNT(keyword_id) AS keyword_count
    FROM 
        movie_keyword 
    GROUP BY 
        movie_id
) mk ON mk.movie_id IN (SELECT am.movie_id FROM ActorMovies am WHERE am.actor_id = ms.actor_id)
ORDER BY 
    ms.movie_count DESC, 
    ms.actor_name;
