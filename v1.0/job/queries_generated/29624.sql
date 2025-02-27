WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.movie_keyword,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 5
),
actors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ci.movie_id,
        ci.nr_order
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    ORDER BY 
        ci.movie_id, ci.nr_order
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.movie_keyword,
    ARRAY_AGG(DISTINCT CONCAT(a.actor_name, ' (Order: ', a.nr_order, ')')) AS cast_list
FROM 
    top_movies tm
JOIN 
    actors a ON a.movie_id = tm.movie_id
GROUP BY 
    tm.movie_id, tm.movie_title, tm.production_year, tm.movie_keyword
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;

