WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ka.name, ', ') AS featured_actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ka ON c.person_id = ka.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000 AND 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
    GROUP BY 
        t.id, t.title, t.production_year
), 
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        featured_actors,
        keywords,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
    WHERE 
        cast_count > 5
)
SELECT 
    rank,
    title,
    production_year,
    cast_count,
    featured_actors,
    keywords
FROM 
    top_movies
WHERE 
    rank <= 10
ORDER BY 
    rank;
