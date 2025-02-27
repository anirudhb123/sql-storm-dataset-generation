WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        a.surname_pcode,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON c.movie_id = m.id
    JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword, a.name, a.surname_pcode
),
filtered_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        movie_keyword,
        actor_name,
        surname_pcode,
        total_cast,
        DENSE_RANK() OVER (PARTITION BY movie_keyword ORDER BY total_cast DESC) AS keyword_rank
    FROM 
        movie_details
)
SELECT 
    f.movie_id,
    f.movie_title,
    f.production_year,
    f.movie_keyword,
    f.actor_name,
    f.surname_pcode,
    f.total_cast
FROM 
    filtered_movies f
WHERE 
    f.keyword_rank <= 3
ORDER BY 
    f.movie_keyword, f.total_cast DESC;

This query performs the following actions:

1. It first creates a common table expression (CTE) called `movie_details` to gather movie information, related keywords, actor names, and cast counts for movies produced between 2000 and 2023.
2. It then defines another CTE, `filtered_movies`, that ranks the movies by their total cast count within each keyword category using a dense ranking function.
3. Finally, it selects the top 3 ranked movies for each keyword and orders the results by keyword and total cast in descending order, providing a detailed overview of popular movies based on keyword association and actor participation.
