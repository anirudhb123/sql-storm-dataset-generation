
WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title, 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC, t.production_year DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, t.title, t.production_year
),

top_rated_movies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.keyword_count,
        r.role
    FROM 
        ranked_movies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_title = (SELECT title FROM aka_title WHERE id = cc.movie_id)
    LEFT JOIN 
        role_type r ON cc.subject_id = r.id
    WHERE 
        rm.rank <= 10
)

SELECT 
    ROUND(AVG(CAST(top_rated_movies.cast_count AS DECIMAL)), 2) AS avg_cast_count,
    ROUND(AVG(CAST(top_rated_movies.keyword_count AS DECIMAL)), 2) AS avg_keyword_count,
    STRING_AGG(DISTINCT CONCAT(top_rated_movies.movie_title, ' (', top_rated_movies.production_year, ')'), ', ') AS movies
FROM 
    top_rated_movies
GROUP BY 
    top_rated_movies.role
ORDER BY 
    avg_cast_count DESC;
