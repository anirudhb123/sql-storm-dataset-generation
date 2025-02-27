WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
top_movies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.cast_count, 
        rm.aka_names
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.cast_count, 
    unnest(tm.aka_names) AS aka_name
FROM 
    top_movies tm
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
