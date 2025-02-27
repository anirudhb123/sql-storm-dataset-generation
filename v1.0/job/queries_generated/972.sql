WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
popular_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank_per_year <= 5
),
unique_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    pm.title,
    pm.production_year,
    pm.cast_count,
    COALESCE(uk.keywords, 'No keywords') AS keywords
FROM 
    popular_movies pm
LEFT JOIN 
    unique_keywords uk ON pm.title = (SELECT at.title FROM aka_title at WHERE at.movie_id = uk.movie_id)
ORDER BY 
    pm.production_year DESC, pm.cast_count DESC;
