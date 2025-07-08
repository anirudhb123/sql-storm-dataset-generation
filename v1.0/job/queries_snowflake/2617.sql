
WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        at.id, at.title, at.production_year
),
popular_keywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.keyword_id) > 1
),
movie_info_summary AS (
    SELECT 
        m.id AS movie_id,
        LISTAGG(DISTINCT mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS info_notes
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(pk.keyword, 'No Keywords') AS frequent_keyword,
    COALESCE(mi.info_notes, 'No Info') AS movie_summary
FROM 
    ranked_movies rm
LEFT JOIN 
    popular_keywords pk ON rm.title = (SELECT at.title FROM aka_title at WHERE at.id = pk.movie_id)
LEFT JOIN 
    movie_info_summary mi ON rm.title = (SELECT m.title FROM title m WHERE m.id = mi.movie_id)
WHERE 
    rm.rank <= 10 
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
