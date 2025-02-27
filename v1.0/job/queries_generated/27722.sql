WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    ORDER BY 
        rm.cast_count DESC
    LIMIT 10
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.cast_count,
    m.keywords,
    COUNT(DISTINCT ci.person_id) AS unique_actors
FROM 
    TopMovies m
JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
GROUP BY 
    m.movie_id, m.title, m.production_year, m.cast_count, m.keywords
HAVING 
    COUNT(DISTINCT ci.person_id) > 5;
