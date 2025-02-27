WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title,
        t.production_year,
        array_agg(DISTINCT k.keyword) AS keywords,
        COUNT(c.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        *, 
        ARRAY_LENGTH(keywords, 1) AS keyword_count
    FROM 
        ranked_movies
    WHERE 
        rank_by_cast <= 5
)
SELECT 
    l.link_type, 
    COUNT(m.movie_id) AS linked_movie_count, 
    AVG(tm.keyword_count) AS avg_keywords,
    MAX(tm.production_year) AS latest_year
FROM 
    top_movies tm
JOIN 
    movie_link ml ON tm.movie_id = ml.movie_id
JOIN 
    link_type l ON ml.link_type_id = l.id
GROUP BY 
    l.link_type
ORDER BY 
    linked_movie_count DESC;

This query performs the following tasks:

1. **Ranked Movies CTE**: It retrieves movies along with their keywords and cast counts, ranking them by the number of cast members per year.
   
2. **Top Movies CTE**: It filters to get only the top 5 movies by cast size from each production year and calculates the number of distinct keywords for these movies.

3. **Final Selection**: It joins the top movies with movie links and link types to count how many movies are linked for each type, while also finding the average number of keywords and the most recent production year for the selected movies. 

The results will give insights into which link types correspond to the highest number of linked movies.
