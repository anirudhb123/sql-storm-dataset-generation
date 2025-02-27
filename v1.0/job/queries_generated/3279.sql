WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
), ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT cc.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    GROUP BY 
        ak.name
), MovieKeywords AS (
    SELECT 
        mt.title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id, mt.title
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    ak.actor_name,
    ak.movies_count,
    mk.keyword_count,
    CASE 
        WHEN rm.cast_count IS NULL THEN 'No Cast'
        ELSE 'Has Cast' 
    END AS cast_status
FROM 
    RankedMovies rm
JOIN 
    ActorInfo ak ON ak.movies_count > 5
LEFT JOIN 
    MovieKeywords mk ON rm.title = mk.title
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
