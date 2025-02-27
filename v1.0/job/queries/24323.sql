WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
movies_with_keywords AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        ranked_movies r
    LEFT JOIN 
        movie_keyword mk ON r.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        r.movie_id, r.title, r.production_year
),
movies_with_info AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(mi.info, 'No Information') AS info,
        m.keywords
    FROM 
        movies_with_keywords m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    WHERE 
        m.production_year > 2000
)
SELECT 
    mwi.title,
    mwi.production_year,
    mwi.info,
    mwi.keywords,
    CASE
        WHEN NULLIF(mwi.info, '') IS NULL THEN 'Unknown'
        WHEN mwi.keywords IS NOT NULL AND ARRAY_LENGTH(mwi.keywords, 1) > 0 THEN 'With Keywords'
        ELSE 'No Keywords'
    END AS keyword_status,
    COALESCE(mwi.keywords[1], 'No Keywords Available') AS first_keyword,
    COUNT(CASE WHEN ci.note IS NOT NULL THEN 1 END) AS non_null_cast_notes,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS average_order
FROM 
    movies_with_info mwi
LEFT JOIN 
    cast_info ci ON mwi.movie_id = ci.movie_id
GROUP BY 
    mwi.movie_id, mwi.title, mwi.production_year, mwi.info, mwi.keywords
HAVING 
    COUNT(ci.id) > 5
ORDER BY 
    mwi.production_year DESC, mwi.title;
