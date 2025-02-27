
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS actors,
        COALESCE(AVG(CAST(mvi.info AS NUMERIC)), 0) AS average_rating,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COALESCE(AVG(CAST(mvi.info AS NUMERIC)), 0) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_info mvi ON at.id = mvi.movie_id AND mvi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        at.id, at.title, at.production_year
), 
ActorMovieCounts AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actors,
    rm.average_rating,
    amc.movie_count,
    CASE 
        WHEN amc.movie_count > 5 AND rm.average_rating IS NOT NULL THEN 'Popular Actor'
        WHEN amc.movie_count <= 5 AND rm.average_rating IS NOT NULL THEN 'Emerging Actor'
        ELSE 'Unknown'
    END AS actor_status,
    CASE 
        WHEN rm.rank <= 3 THEN 'Top Movie'
        ELSE 'Regular Movie'
    END AS movie_status
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorMovieCounts amc ON amc.name = ANY(rm.actors)
WHERE 
    rm.average_rating <> 0
    AND rm.production_year IS NOT NULL
    AND rm.production_year <> 2020
ORDER BY 
    rm.production_year DESC, rm.average_rating DESC;
