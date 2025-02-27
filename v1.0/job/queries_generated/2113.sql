WITH movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword_count, 0) AS keyword_count,
        COALESCE(mc.total_cast, 0) AS total_cast
    FROM 
        aka_title m
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(id) AS keyword_count 
        FROM 
            movie_keyword 
        GROUP BY 
            movie_id
    ) mk ON m.id = mk.movie_id
    LEFT JOIN movie_cast mc ON m.id = mc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword_count,
    md.total_cast,
    ROW_NUMBER() OVER (ORDER BY md.production_year DESC) AS rank
FROM 
    movie_details md
WHERE 
    md.production_year > 2000
    AND (md.keyword_count > 2 OR md.total_cast > 5)
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
