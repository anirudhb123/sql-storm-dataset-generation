WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY YEAR(m.production_year) ORDER BY COUNT(c.id) DESC) AS rank,
        COUNT(c.id) AS cast_count
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id
), 
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 10
), 
movie_keywords AS (
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
    fm.title,
    fm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    fm.cast_count,
    CASE 
        WHEN fm.production_year < 2000 THEN 'Classic'
        WHEN fm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    filtered_movies fm
LEFT JOIN 
    movie_keywords mk ON fm.movie_id = mk.movie_id
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;
