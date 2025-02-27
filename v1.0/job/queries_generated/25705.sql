WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        ARRAY_AGG(DISTINCT aka_name.name) AS aka_names,
        ARRAY_AGG(DISTINCT keyword.keyword) AS keywords,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        RANK() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank_by_cast
    FROM 
        title
    LEFT JOIN 
        aka_title ON title.id = aka_title.movie_id
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    LEFT JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.id, title.title, title.production_year
),
popular_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        aka_names,
        keywords,
        total_cast
    FROM 
        ranked_movies
    WHERE 
        rank_by_cast <= 5
)
SELECT 
    pm.movie_title,
    pm.production_year,
    STRING_AGG(DISTINCT name.name, ', ') AS cast_names,
    STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords,
    CASE 
        WHEN pm.production_year < 2000 THEN 'Classic'
        WHEN pm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_category
FROM 
    popular_movies pm
LEFT JOIN 
    cast_info ci ON pm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name name ON ci.person_id = name.person_id
LEFT JOIN 
    movie_keyword mk ON pm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    pm.movie_title, pm.production_year
ORDER BY 
    pm.production_year DESC;
