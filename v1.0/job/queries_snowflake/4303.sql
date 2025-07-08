
WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
top_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank_by_cast <= 5
),
movie_keywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
detailed_movies AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(a.name, 'Unknown') AS main_actor
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_keywords mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        cast_info ci ON tm.title = (SELECT a.title FROM aka_title a WHERE a.id = ci.movie_id)
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.nr_order = 1
)
SELECT 
    d.title,
    d.production_year,
    d.cast_count,
    d.keywords,
    UPPER(d.main_actor) AS main_actor_upper
FROM 
    detailed_movies d
ORDER BY 
    d.production_year DESC, 
    d.cast_count DESC
LIMIT 10;
