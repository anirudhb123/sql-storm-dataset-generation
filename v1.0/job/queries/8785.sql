WITH movie_cast AS (
    SELECT 
        c.movie_id, 
        STRING_AGG(a.name, ', ') AS cast_names, 
        COUNT(DISTINCT c.person_id) AS total_cast_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
), movie_keywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), movie_details AS (
    SELECT 
        m.id, 
        m.title, 
        m.production_year, 
        mc.cast_names, 
        mk.keywords, 
        COALESCE(mi.info, 'No info') AS movie_info
    FROM 
        title m
    LEFT JOIN 
        movie_cast mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keywords mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    ORDER BY 
        m.production_year DESC
)
SELECT 
    md.title, 
    md.production_year, 
    md.cast_names, 
    md.keywords, 
    md.movie_info
FROM 
    movie_details md
WHERE 
    md.production_year >= 2000 
    AND md.keywords ILIKE '%action%'
    AND md.cast_names IS NOT NULL;
