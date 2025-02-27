WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
movie_information AS (
    SELECT 
        m.id AS movie_id,
        MIN(CASE WHEN m.info_type_id = 1 THEN m.info END) AS genre,
        MIN(CASE WHEN m.info_type_id = 2 THEN m.info END) AS director
    FROM 
        movie_info m
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cd.cast_count,
    cd.cast_names,
    mi.genre,
    mi.director,
    COALESCE(cd.cast_count * 10, 0) AS project_value
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_details cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    movie_information mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
