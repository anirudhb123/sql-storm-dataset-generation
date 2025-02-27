WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ka.person_id) DESC) AS rank
    FROM 
        aka_title t
        JOIN cast_info ca ON t.movie_id = ca.movie_id
        JOIN aka_name ka ON ca.person_id = ka.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 3
),
movies_with_keywords AS (
    SELECT 
        t.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
        JOIN title t ON mk.movie_id = t.id
    GROUP BY 
        t.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mkw.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(DISTINCT ci.id) 
     FROM cast_info ci 
     WHERE ci.movie_id = tm.movie_id AND ci.note IS NOT NULL) AS non_null_cast_count,
    (SELECT AVG(mo.rank) 
     FROM (SELECT 
               DISTINCT rc.rank 
           FROM 
               ranked_movies rc 
           WHERE 
               rc.production_year = tm.production_year) mo) AS avg_rank_of_year
FROM 
    top_movies tm
LEFT JOIN 
    movies_with_keywords mkw ON tm.movie_id = mkw.movie_id
WHERE 
    tm.production_year IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;

### Explanation:
- **CTEs**: Three Common Table Expressions are defined:
  - `ranked_movies`: To rank each movie based on the number of cast members per production year.
  - `top_movies`: To filter the top 3 ranked movies for each production year.
  - `movies_with_keywords`: To aggregate keywords for each movie.
  
- **Main Select**: The final selection gathers movie titles, their production years, associated keywords, a count of non-null casts, and the average rank of movies in the same year.

- **COALESCE**: Used to provide a fallback when there are no keywords, showing 'No keywords'.

- **Subqueries**: Two correlated subqueries calculate the count of distinct non-null cast entries and the average rank for the production year.

- **Outer Join**: A left join is utilized to ensure we keep all top movies even if they don’t have associated keywords.

- **Bizarre SQL Semantics**: The use of `STRING_AGG` ensures retrieval of a list of keywords but if there exist no keywords, it defaults to specifying 'No keywords' thanks to the `COALESCE`.

This query is designed to evaluate the performance of complex joins, aggregations, and subqueries while accessing various dimensions of the movie data, showcasing SQL's capabilities in handling intricate logic and relationships.
