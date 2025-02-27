WITH ranked_titles AS (
    SELECT 
        a.title AS title,
        t.production_year AS year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title a 
    JOIN 
        title t ON a.movie_id = t.id
    JOIN 
        cast_info c ON a.movie_id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        a.title, t.production_year
),

top_movies AS (
    SELECT 
        title, 
        year,
        cast_count,
        actor_names,
        year_rank
    FROM 
        ranked_titles
    WHERE 
        year_rank <= 5  -- Top 5 movies per year
)

SELECT 
    tm.title, 
    tm.year, 
    tm.cast_count, 
    tm.actor_names,
    k.keyword AS movie_keyword
FROM 
    top_movies tm
LEFT JOIN 
    movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE movie_id = tm.title LIMIT 1)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
ORDER BY 
    tm.year DESC, 
    tm.cast_count DESC;

This SQL query performs several operations to benchmark string processing capabilities:

1. **CTEs (Common Table Expressions)**: Two CTEs are utilized – `ranked_titles`, which aggregates movies' titles by year and counts their cast, and `top_movies`, which filters to show the top 5 movies by cast count for each year.

2. **String Aggregation**: The query computes the aggregated names of actors associated with each title using `STRING_AGG`, showcasing string processing strengths.

3. **Ranking**: It ranks the titles within their respective years based on cast count, using `ROW_NUMBER()`.

4. **Joins**: The query joins multiple tables to extract relevant movie and keyword data, highlighting the complexity of string processing in relational databases.

5. **Ordering**: The results are ordered by production year (descending) and cast count (descending), allowing for straightforward benchmarking of query performance based on attributes of string processing.

This complex structure aims to fully explore the capabilities of SQL in relation to string manipulation and aggregation for benchmarking purposes.
