
WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id, 
        a.title, 
        a.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tvSeries'))
),
cast_summary AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS total_cast, 
        COUNT(CASE WHEN ci.nr_order = 1 THEN 1 END) AS main_cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
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
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cs.total_cast,
    cs.main_cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    (SELECT AVG(rm2.year_rank) 
     FROM ranked_movies rm2 
     WHERE rm2.production_year = rm.production_year) AS avg_year_rank
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_summary cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.year_rank <= 5
GROUP BY 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    cs.total_cast, 
    cs.main_cast_count, 
    mk.keywords
ORDER BY 
    rm.production_year DESC, 
    rm.movie_id;
