
WITH movie_cast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(a.name, ',') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ',') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        mc.cast_names,
        mk.keywords
    FROM 
        title t
    LEFT JOIN 
        movie_cast mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keywords mk ON t.id = mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_names,
    md.keywords
FROM 
    movie_details md
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
