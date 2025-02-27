WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
selected_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(ROUND(AVG(CASE WHEN len(note) IS NULL THEN 0 ELSE LENGTH(note) END)), 0) AS avg_note_length
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_info mi ON rm.production_year = mi.movie_id
    WHERE 
        rm.rank <= 5 -- Select top 5 movies per year based on cast count
    GROUP BY 
        rm.title, rm.production_year, rm.cast_count
),
movie_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    sm.title,
    sm.production_year,
    sm.cast_count,
    sm.avg_note_length,
    COALESCE(mk.keywords, 'No keywords available') AS keywords
FROM 
    selected_movies sm
LEFT JOIN 
    movie_info m ON sm.production_year = m.movie_id
LEFT JOIN 
    movie_keywords mk ON mk.movie_id = sm.production_year
WHERE 
    sm.cast_count > 0
ORDER BY 
    sm.production_year ASC, 
    sm.cast_count DESC;
