WITH movie_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

complete_movie_info AS (
    SELECT 
        mc.movie_id,
        mc.movie_title,
        mc.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        mc.cast_names
    FROM 
        movie_cast mc
    LEFT JOIN 
        movie_keywords mk ON mc.movie_id = mk.movie_id
)

SELECT 
    cmi.movie_title,
    cmi.production_year,
    cmi.keywords,
    cmi.cast_names,
    COUNT(DISTINCT mci.info) AS info_count
FROM 
    complete_movie_info cmi
LEFT JOIN 
    movie_info mci ON cmi.movie_id = mci.movie_id
GROUP BY 
    cmi.movie_title, cmi.production_year, cmi.keywords, cmi.cast_names
HAVING 
    COUNT(DISTINCT mci.info) > 0
ORDER BY 
    cmi.production_year DESC, cmi.movie_title;
