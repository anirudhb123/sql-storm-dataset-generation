
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(AVG(CASE WHEN c.note IS NOT NULL THEN c.nr_order END), 0) AS avg_cast_order,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
top_movies AS (
    SELECT 
        *
    FROM 
        ranked_movies
    WHERE 
        year_rank <= 10
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
full_movie_details AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.avg_cast_order,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_keywords mk ON tm.movie_id = mk.movie_id
)
SELECT 
    fmd.title,
    fmd.production_year,
    fmd.avg_cast_order,
    CASE 
        WHEN fmd.avg_cast_order IS NULL THEN 'No Cast Data'
        WHEN fmd.avg_cast_order < 3 THEN 'Low Cast Presence'
        ELSE 'Sufficient Cast Presence'
    END AS cast_presence,
    LENGTH(fmd.keywords) AS keyword_length,
    CASE 
        WHEN LENGTH(fmd.keywords) > 0 THEN 
            CONCAT('Keywords: ', fmd.keywords)
        ELSE 
            'No Keywords Available'
    END AS keyword_info
FROM 
    full_movie_details fmd
WHERE 
    fmd.production_year BETWEEN 2000 AND 2022
ORDER BY 
    fmd.production_year DESC, fmd.avg_cast_order DESC;
