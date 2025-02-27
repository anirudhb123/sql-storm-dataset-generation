WITH RECURSIVE movie_with_cast AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.person_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_order
    FROM
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 1990 AND 2023
),
actor_movie_counts AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS movies_count
    FROM 
        movie_with_cast
    GROUP BY 
        actor_name
    HAVING 
        COUNT(DISTINCT movie_id) > 5
),
keyword_stats AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
movie_info_with_keywords AS (
    SELECT 
        w.movie_id,
        w.title,
        w.production_year,
        w.actor_name,
        `COALESCE`(ki.keywords, 'No Keywords') AS keywords
    FROM 
        movie_with_cast w
    LEFT JOIN 
        keyword_stats ki ON w.movie_id = ki.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.actor_name,
    m.keywords,
    a.movies_count
FROM 
    movie_info_with_keywords m
JOIN 
    actor_movie_counts a ON m.actor_name = a.actor_name
WHERE 
    m.production_year = (
        SELECT 
            MAX(production_year) 
        FROM 
            movie_info_with_keywords
    )
ORDER BY 
    m.actor_name, m.title;

This SQL query executes the following steps:

1. **Recursive CTE `movie_with_cast`** gathers movies, their production years, and the actors associated with them, filtered by production year.
    
2. **CTE `actor_movie_counts`** aggregates actor names with the count of distinct movies they have participated in, ensuring we only retain actors who have worked in more than 5 films.

3. **CTE `keyword_stats`** collates keywords associated with each movie, allowing for structured keyword association with films.

4. **Final Selection** combines the movie information with the generated keyword outputs. 

5. The results are filtered to include only the movies from the latest production year available in the dataset and are ordered by actor name and movie title. 

This query intentionally utilizes complex joins, aggregates, string concatenation, and a subquery to showcase SQL capabilities for performance benchmarking.
