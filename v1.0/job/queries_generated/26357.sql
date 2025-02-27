WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS known_actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id
),
filtered_ranked_movies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        known_actors,
        movie_keywords
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
)
SELECT 
    production_year,
    STRING_AGG(title || ' (Cast: ' || cast_count || ', Actors: ' || 
               ARRAY_TO_STRING(known_actors, ', ') || ', Keywords: ' ||
               movie_keywords || ')', '; ') AS movie_summary
FROM 
    filtered_ranked_movies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
