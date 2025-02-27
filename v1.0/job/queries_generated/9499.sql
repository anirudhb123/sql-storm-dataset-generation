WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id
    ORDER BY 
        cast_count DESC
    LIMIT 10
),
movie_keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
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
    mk.keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.id = mk.movie_id
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
