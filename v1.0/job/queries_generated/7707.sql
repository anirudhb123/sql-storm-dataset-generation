WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        title m
    JOIN 
        movie_companies mc ON mc.movie_id = m.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        complete_cast cc ON cc.movie_id = m.id
    JOIN 
        cast_info ci ON ci.movie_id = m.id
    JOIN 
        aka_name an ON an.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        m.production_year >= 2000 AND 
        cn.country_code = 'USA'
    GROUP BY 
        m.id
    ORDER BY 
        cast_count DESC
    LIMIT 10
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    STRING_AGG(DISTINCT rm.keywords, ', ') AS keywords
FROM 
    RankedMovies rm
JOIN 
    movie_info mi ON mi.movie_id = rm.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, rm.cast_count
ORDER BY 
    rm.cast_count DESC;
