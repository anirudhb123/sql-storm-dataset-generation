
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(c.id) AS cast_count
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
top_movies AS (
    SELECT
        movie_id,
        title,
        production_year,
        keywords,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC, production_year DESC) AS rnk
    FROM 
        ranked_movies
    WHERE 
        production_year > 2000
),
movie_details AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        ARRAY_AGG(DISTINCT p.info) AS person_infos
    FROM 
        top_movies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        person_info p ON cc.subject_id = p.person_id
    WHERE 
        tm.rnk <= 10
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, tm.cast_count
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    STRING_AGG(DISTINCT info_type.info, ', ') AS additional_info
FROM 
    movie_details md
LEFT JOIN 
    movie_info mi ON md.movie_id = mi.movie_id
LEFT JOIN 
    info_type ON mi.info_type_id = info_type.id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.cast_count
ORDER BY 
    md.cast_count DESC, md.production_year DESC;
