WITH movie_ratings AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS genre,
        c.character AS cast_member,
        COALESCE(i.info, 'No info available') AS additional_info
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        movie_info mi ON a.id = mi.movie_id
    LEFT JOIN 
        info_type i ON mi.info_type_id = i.id
    WHERE 
        a.production_year >= 2000 
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        genre,
        COUNT(cast_member) AS cast_count
    FROM 
        movie_ratings
    GROUP BY 
        movie_title, production_year, genre
    HAVING 
        COUNT(cast_member) > 3
)
SELECT 
    movie_title,
    production_year,
    genre,
    cast_count
FROM 
    top_movies
ORDER BY 
    production_year DESC, cast_count DESC;
