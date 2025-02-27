WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
    INNER JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ca ON ca.movie_id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) as rank
    FROM 
        ranked_movies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names
FROM 
    top_movies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
