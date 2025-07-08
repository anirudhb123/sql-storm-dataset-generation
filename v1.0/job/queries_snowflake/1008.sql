
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rn,
        COUNT(c.person_id) AS cast_count,
        t.id AS movie_id
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
), ActorInfo AS (
    SELECT 
        a.name,
        COUNT(c.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON t.id = c.movie_id
    GROUP BY 
        a.name
), KeywordStats AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    ai.name AS top_actor,
    ai.movie_count,
    ai.avg_production_year,
    ks.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorInfo ai ON ai.movie_count = (
        SELECT 
            MAX(movie_count) FROM ActorInfo
    )
LEFT JOIN 
    KeywordStats ks ON ks.movie_id = rm.movie_id
WHERE 
    rm.rn = 1
  AND 
    rm.production_year > 2000
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
