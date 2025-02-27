WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        kind_id,
        cast_count,
        actor_names
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    kt.kind AS kind_of_movie,
    tm.cast_count,
    tm.actor_names
FROM 
    top_movies tm
LEFT JOIN 
    kind_type kt ON tm.kind_id = kt.id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
