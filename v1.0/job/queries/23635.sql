WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS cast_rank,
        COALESCE(k.keyword, 'Unknown') AS movie_keyword
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
movies_with_info AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mi.info, 'No Info') AS movie_info,
        rm.movie_keyword,
        rm.cast_rank
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
),
filtered_movies AS (
    SELECT 
        mwi.movie_id, 
        mwi.title,
        mwi.production_year,
        mwi.movie_info,
        mwi.movie_keyword,
        mwi.cast_rank,
        CASE 
            WHEN mwi.cast_rank <= 3 THEN 'Top Cast'
            ELSE 'Other Cast'
        END AS cast_category
    FROM 
        movies_with_info mwi
    WHERE 
        mwi.production_year BETWEEN 2000 AND 2020
        AND mwi.movie_info IS NOT NULL
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.movie_info,
    f.movie_keyword,
    f.cast_category,
    COUNT(DISTINCT ci.id) AS total_cast,
    AVG(COALESCE(NULLIF(ci.nr_order, 0), NULL)) AS avg_order_not_zero
FROM 
    filtered_movies f
LEFT JOIN 
    cast_info ci ON f.movie_id = ci.movie_id
GROUP BY 
    f.movie_id, f.title, f.production_year, f.movie_info, f.movie_keyword, f.cast_category
ORDER BY 
    f.production_year DESC, total_cast DESC, f.title ASC;
