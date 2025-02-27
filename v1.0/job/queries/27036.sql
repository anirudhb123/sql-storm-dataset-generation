WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.actors,
        CASE 
            WHEN rm.cast_count > 10 THEN 'High'
            WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Moderate'
            ELSE 'Low' 
        END AS cast_size
    FROM 
        ranked_movies rm
    WHERE 
        rm.production_year >= 2010
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.cast_count,
    fm.actors,
    fm.cast_size
FROM 
    filtered_movies fm
ORDER BY 
    fm.cast_size DESC,
    fm.production_year DESC;
