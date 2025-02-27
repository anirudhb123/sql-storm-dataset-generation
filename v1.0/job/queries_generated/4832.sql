WITH ranked_movies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
high_cast_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.year_rank <= 3
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
),
final_result AS (
    SELECT 
        hcm.title,
        hcm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        hcm.cast_count
    FROM 
        high_cast_movies hcm
    LEFT JOIN 
        movie_keywords mk ON hcm.title = (SELECT t.title FROM title t WHERE t.imdb_id = hcm.production_year) 
)
SELECT 
    title,
    production_year,
    keywords,
    cast_count
FROM 
    final_result
WHERE 
    (cast_count > 5 OR keywords <> 'No Keywords')
ORDER BY 
    production_year DESC, cast_count DESC;
