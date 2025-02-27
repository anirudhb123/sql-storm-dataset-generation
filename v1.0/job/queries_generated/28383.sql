WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id AND cc.movie_id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
PopularActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(c.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(c.movie_id) > 5
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.keyword_count,
    pa.actor_name
FROM 
    RankedMovies rm
JOIN 
    PopularActors pa ON rm.cast_count > 5
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
