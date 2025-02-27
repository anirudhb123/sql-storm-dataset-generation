WITH movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
genre_counts AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(kt.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
top_movies AS (
    SELECT 
        at.title,
        at.production_year,
        mc.company_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        gc.genres
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        movie_keyword_counts mkc ON at.id = mkc.movie_id
    LEFT JOIN 
        genre_counts gc ON at.id = gc.movie_id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        at.title, at.production_year, mc.company_id, mkc.keyword_count, gc.genres
    ORDER BY 
        cast_count DESC, keyword_count DESC
    LIMIT 10
)
SELECT 
    t.title,
    t.production_year,
    t.cast_count,
    t.keyword_count,
    t.genres,
    c.name AS company_name
FROM 
    top_movies t
LEFT JOIN 
    company_name c ON t.company_id = c.id
ORDER BY 
    t.cast_count DESC;