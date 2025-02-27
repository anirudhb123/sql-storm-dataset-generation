WITH ranked_movies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
movie_keywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
top_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        mk.keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keywords mk ON rm.title = mk.movie_id
    WHERE 
        rm.rank_by_cast <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.cast_count, 0) AS cast_count,
    COALESCE(tm.keywords, 'No keywords') AS keywords
FROM 
    top_movies tm
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
