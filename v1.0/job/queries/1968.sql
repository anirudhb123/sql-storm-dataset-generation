
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(c.nr_order) AS average_order
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
high_cast_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.cast_count,
        md.average_order
    FROM 
        movie_details md
    WHERE 
        md.cast_count > 5
),
top_keywords AS (
    SELECT 
        movie_id,
        UNNEST(keywords) AS keyword
    FROM 
        high_cast_movies
    WHERE 
        keywords IS NOT NULL
),
keyword_ranks AS (
    SELECT 
        keyword,
        ROW_NUMBER() OVER (PARTITION BY keyword ORDER BY COUNT(*) DESC) AS rank
    FROM 
        top_keywords
    GROUP BY 
        keyword
)
SELECT 
    hm.movie_id,
    hm.title,
    hm.production_year,
    kp.keyword,
    kp.rank
FROM 
    high_cast_movies hm
JOIN 
    top_keywords tp ON hm.movie_id = tp.movie_id
JOIN 
    keyword_ranks kp ON tp.keyword = kp.keyword
WHERE 
    kp.rank <= 3
ORDER BY 
    hm.production_year DESC, hm.cast_count DESC;
