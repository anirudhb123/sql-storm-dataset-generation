WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        t.production_year,
        COUNT(c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS co_actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        title AS t
    JOIN 
        aka_title AS a ON t.id = a.movie_id
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    JOIN 
        aka_name AS ak ON ak.person_id = c.person_id
    WHERE 
        a.kind_id IS NOT NULL 
        AND t.production_year >= 2000
    GROUP BY 
        a.title, t.production_year
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        actor_count,
        co_actors
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.actor_count,
    tm.co_actors,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    top_movies AS tm
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = tm.movie_id
LEFT JOIN 
    keyword AS k ON k.id = mk.keyword_id
GROUP BY 
    tm.movie_title, tm.production_year, tm.actor_count, tm.co_actors
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;

This SQL query benchmarks string processing by retrieving the top 5 movies produced each year since 2000, along with their related co-actors and associated keywords. It demonstrates string aggregation by concatenating actor names and keywords into single strings, focusing on performance while analyzing the string manipulation aspects of the dataset.
