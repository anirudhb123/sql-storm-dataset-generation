WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title m
    INNER JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
top_movies AS (
    SELECT 
        movie_id, title, production_year 
    FROM 
        ranked_movies 
    WHERE 
        rank <= 10
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
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT c.person_id) AS cast_count,
    AVG(CASE WHEN ci.role_id IS NULL THEN 0 ELSE 1 END) AS role_assigned_ratio
FROM 
    top_movies t
LEFT JOIN 
    complete_cast cc ON t.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_keywords mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    role_type ci ON c.role_id = ci.id
WHERE 
    t.production_year > 2000
GROUP BY 
    t.title, t.production_year, mk.keywords
ORDER BY 
    t.production_year DESC, cast_count DESC;
