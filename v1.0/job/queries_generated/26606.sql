WITH MovieStats AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS unique_actor_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS production_companies
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_key mk ON mt.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        unique_actor_names,
        keyword_count,
        production_companies,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM 
        MovieStats
)

SELECT 
    movie_id,
    movie_title,
    production_year,
    cast_count,
    TRIM(BOTH '{}' FROM unique_actor_names::TEXT) AS unique_actor_names,
    keyword_count,
    production_companies
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    cast_count DESC;

This query provides insights into the top 10 movies based on the number of distinct cast members, including the production year, unique actor names, and the companies involved in the production. It utilizes Common Table Expressions (CTEs) to structure the query and improve readability for benchmarking string processing within the database schema provided.
