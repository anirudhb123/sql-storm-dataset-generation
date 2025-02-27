WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        RANK() OVER (ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
),
movie_info_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    r.title,
    r.production_year,
    r.cast_count,
    COALESCE(mik.keywords, ARRAY[]::text[]) AS keywords
FROM 
    ranked_movies r
LEFT JOIN 
    movie_info_with_keywords mik ON r.title = mik.title
WHERE 
    r.rank <= 10
ORDER BY 
    r.rank;
