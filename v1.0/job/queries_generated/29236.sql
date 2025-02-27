WITH movie_summary AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS actor_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
top_movies AS (
    SELECT 
        ms.movie_title,
        ms.production_year,
        ms.actor_names,
        ms.keyword_count,
        ms.company_count,
        ROW_NUMBER() OVER (ORDER BY ms.keyword_count DESC, ms.company_count DESC) AS rank
    FROM 
        movie_summary ms
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.actor_names,
    tm.keyword_count,
    tm.company_count
FROM 
    top_movies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.keyword_count DESC, tm.company_count DESC;

This query identifies the top 10 movies produced between 2000 and 2023 based on the number of unique keywords associated with each movie and the number of different companies involved in the movie's production. It aggregates the actor names for each movie, providing a summarization of essential movie-related information through Common Table Expressions (CTEs) to facilitate benchmarking of string processing in SQL.
