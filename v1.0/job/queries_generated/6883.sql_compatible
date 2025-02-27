
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.title, t.production_year
),
top_movies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        actor_names,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actor_names
FROM 
    top_movies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
