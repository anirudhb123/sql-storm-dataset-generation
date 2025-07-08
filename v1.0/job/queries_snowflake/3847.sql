
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
), high_rated_movies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 5
), movie_keyword_count AS (
    SELECT 
        mk.movie_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
), movie_info_summary AS (
    SELECT 
        mi.movie_id, 
        LISTAGG(CASE WHEN it.info = 'rating' THEN mi.info END, ', ') AS ratings,
        LISTAGG(CASE WHEN it.info = 'duration' THEN mi.info END, ', ') AS durations
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    hm.title,
    hm.production_year,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    mis.ratings,
    mis.durations
FROM 
    high_rated_movies hm
LEFT JOIN 
    movie_keyword_count mkc ON hm.movie_id = mkc.movie_id
LEFT JOIN 
    movie_info_summary mis ON hm.movie_id = mis.movie_id
ORDER BY 
    hm.production_year DESC, 
    keyword_count DESC;
