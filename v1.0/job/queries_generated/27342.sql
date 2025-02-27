WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM title m
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    LEFT JOIN aka_title ak ON m.id = ak.movie_id
    GROUP BY m.id, m.title, m.production_year
),
recent_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.aka_names
    FROM ranked_movies rm
    WHERE rm.production_year >= (SELECT MAX(production_year) - 10 FROM title)
),
popular_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.cast_count,
        DENSE_RANK() OVER (ORDER BY rm.cast_count DESC) AS popularity_rank
    FROM ranked_movies rm
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.cast_count,
    r.aka_names,
    p.popularity_rank
FROM recent_movies r
JOIN popular_movies p ON r.movie_id = p.movie_id
WHERE p.popularity_rank <= 10
ORDER BY r.production_year DESC, p.popularity_rank;

This query performs the following tasks:

1. **ranked_movies CTE**: It selects movies along with their cast count by joining with the `cast_info` and `aka_title` tables, aggregating to get actor names.

2. **recent_movies CTE**: It filters the movies to only include those produced in the last 10 years.

3. **popular_movies CTE**: It ranks the most popular movies based on the number of cast members.

4. Finally, it selects the top 10 popular recent movies and sorts them by their production year in descending order while including their popularity rank.
