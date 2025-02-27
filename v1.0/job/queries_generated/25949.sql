WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        MAX(CASE WHEN k.keyword IS NOT NULL THEN k.keyword END) AS first_keyword,
        CHAR_LENGTH(a.title) AS title_length
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id, a.title, a.production_year
),
average_title_length AS (
    SELECT 
        AVG(title_length) AS avg_length
    FROM 
        ranked_movies
),
ranked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    r.rank,
    r.movie_title,
    r.production_year,
    r.cast_count,
    r.actor_names,
    r.first_keyword,
    avg.avg_length
FROM 
    ranked r
CROSS JOIN 
    average_title_length avg
WHERE 
    r.cast_count >= (SELECT AVG(cast_count) FROM ranked_movies)
ORDER BY 
    r.rank
LIMIT 10;
