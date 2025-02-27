WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS year_ranking
    FROM
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.year_ranking <= 5
),
actors_with_movies AS (
    SELECT 
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN 
        title t ON cc.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    a.actor_name,
    tm.title,
    tm.production_year,
    COALESCE(mk.keyword, 'None') AS keyword,
    CASE 
        WHEN tm.cast_count IS NULL THEN 'No cast information'
        ELSE CAST(tm.cast_count AS TEXT) || ' actors'
    END AS cast_info
FROM 
    top_movies tm
LEFT JOIN 
    movie_keyword mk ON tm.title = mk.movie_id
JOIN 
    actors_with_movies a ON tm.title = a.movie_title AND tm.production_year = a.production_year
ORDER BY 
    tm.production_year DESC, 
    a.actor_name;
