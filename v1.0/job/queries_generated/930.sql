WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), 
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
top_movies AS (
    SELECT 
        m.title,
        m.production_year,
        m.cast_count,
        mk.keywords_list
    FROM 
        ranked_movies m
    LEFT JOIN 
        movie_keywords mk ON m.title = mk.movie_id
    WHERE 
        m.year_rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.keywords_list, 'No Keywords') AS keywords_list,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = tm.title AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office')) AS box_office_info_count
FROM 
    top_movies tm
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
