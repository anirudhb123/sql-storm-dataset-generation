
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year >= 2000 AND 
        cn.country_code = 'USA'
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    STRING_AGG(k.keyword, ', ') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordMovies k ON rm.movie_id = k.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, rm.cast_count
ORDER BY 
    rm.cast_count DESC, rm.production_year DESC
LIMIT 10;
