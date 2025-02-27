WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
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
extended_info AS (
    SELECT 
        m.movie_id,
        COALESCE(k.keywords, 'No keywords') AS keywords,
        COALESCE(m.title, 'Untitled') AS title,
        COALESCE(m.production_year::text, 'Unknown') AS production_year,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = m.movie_id) AS complete_cast_size
    FROM 
        ranked_movies m
    LEFT JOIN 
        movie_keywords k ON m.movie_id = k.movie_id
)
SELECT 
    ei.title,
    ei.production_year,
    ei.keywords,
    ei.complete_cast_size,
    CASE 
        WHEN ei.complete_cast_size > 5 THEN 'Large Cast'
        WHEN ei.complete_cast_size BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    extended_info ei
WHERE 
    ei.rank <= 3
ORDER BY 
    ei.production_year DESC, ei.complete_cast_size DESC;
