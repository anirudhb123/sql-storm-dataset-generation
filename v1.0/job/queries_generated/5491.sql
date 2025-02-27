WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.aka_names
    FROM 
        ranked_movies rm
    WHERE 
        rm.rn = 1
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    string_agg(tm.aka_names, ', ') AS all_aka_names
FROM 
    top_movies tm
JOIN 
    movie_info mi ON tm.title = mi.info
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
GROUP BY 
    tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC
LIMIT 10;
