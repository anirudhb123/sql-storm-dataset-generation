WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        m.id, m.title, m.production_year
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
),
actor_count AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS total_movies
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
),
filtered_actors AS (
    SELECT 
        actor_name,
        total_movies
    FROM 
        actor_count
    WHERE 
        total_movies > 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    fa.actor_name,
    fa.total_movies
FROM 
    top_movies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    filtered_actors fa ON ak.name = fa.actor_name
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC, 
    fa.total_movies DESC;
