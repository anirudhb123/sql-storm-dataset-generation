WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(v.average_rating, 0) AS average_rating,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COALESCE(v.average_rating, 0) DESC) AS year_rank,
        COUNT(DISTINCT c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title AS t
    LEFT JOIN (
        SELECT 
            movie_id,
            AVG(CASE WHEN rating IS NOT NULL THEN rating ELSE 0 END) AS average_rating
        FROM 
            (
                SELECT 
                    movie_id, 
                    RANDOM() * 10 AS rating  -- Simulating movie ratings
                FROM 
                    title
                GROUP BY 
                    movie_id
            ) AS simulated_ratings
        GROUP BY 
            movie_id
    ) AS v ON t.movie_id = v.movie_id
    LEFT JOIN cast_info AS c ON c.movie_id = t.movie_id 
    WHERE 
        t.production_year IS NOT NULL
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(m.average_rating, 0) AS movie_average_rating,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
    m.cast_count
FROM 
    RankedMovies AS m
LEFT JOIN aka_name AS a ON a.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = m.movie_id)
WHERE 
    m.year_rank <= 3 AND  -- Top 3 rated movies per year
    (m.cast_count > 0 AND m.average_rating >= 5) OR  -- Only include if there are cast members with a reasonable rating
    m.cast_count IS NULL  -- To include movies with no cast in the top ranks
GROUP BY 
    m.movie_id, m.title, m.production_year, m.average_rating, m.cast_count
ORDER BY 
    m.production_year DESC, m.average_rating DESC
LIMIT 10;

-- This query creates a ranked set of movies based on simulated ratings,
-- includes cast names, and allows for inclusion of movies without any cast,
-- while utilizing CTE, the COALESCE function, STRING_AGG for concatenating names,
-- and complex conditions in the WHERE clause.
