WITH movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_list,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
movie_info_ext AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword_list, 'No keywords') AS keywords,
        COALESCE(cd.cast_list, 'No cast') AS cast,
        COALESCE(cd.cast_count, 0) AS cast_count
    FROM 
        title m
    LEFT JOIN 
        movie_keywords mk ON m.id = mk.movie_id
    LEFT JOIN 
        cast_details cd ON m.id = cd.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    keywords,
    cast,
    cast_count
FROM 
    movie_info_ext
WHERE 
    production_year > 2000
ORDER BY 
    production_year DESC, cast_count DESC
LIMIT 10;
