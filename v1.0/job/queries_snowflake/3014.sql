
WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.title, a.production_year
),
filtered_movies AS (
    SELECT 
        rm.title,
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rn <= 5
),
movie_info_aggregates AS (
    SELECT 
        m.movie_id,
        LISTAGG(m.info, ', ') AS movie_info_details,
        MAX(CASE WHEN it.info = 'runtime' THEN m.info END) AS runtime,
        MAX(CASE WHEN it.info = 'genre' THEN m.info END) AS genre
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    GROUP BY 
        m.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(mia.movie_info_details, 'No info available') AS info,
    COALESCE(mia.runtime, 'N/A') AS runtime,
    COALESCE(mia.genre, 'N/A') AS genre,
    CASE 
        WHEN fm.production_year < 2000 THEN 'Pre-2000'
        ELSE 'Post-2000'
    END AS era
FROM 
    filtered_movies fm
LEFT JOIN 
    movie_info_aggregates mia ON fm.title = (SELECT title FROM aka_title WHERE id = mia.movie_id)
ORDER BY 
    fm.production_year DESC, 
    fm.title;
