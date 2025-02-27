WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(yi.rating) AS avg_rating
    FROM
        aka_title ak
    JOIN
        title mt ON ak.movie_id = mt.id
    LEFT JOIN
        cast_info ci ON ci.movie_id = mt.id
    LEFT JOIN
        (SELECT movie_id, AVG(rating) AS rating FROM movie_info WHERE info_type_id = 1 GROUP BY movie_id) yi ON yi.movie_id = mt.id
    GROUP BY
        mt.id, mt.title, mt.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        aka_names,
        cast_count,
        RANK() OVER (ORDER BY avg_rating DESC) AS movie_rank
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5
)

SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.aka_names,
    tm.cast_count,
    tm.movie_rank,
    ct.kind AS company_type,
    cn.name AS company_name
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON mc.movie_id = tm.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    tm.movie_rank <= 10
ORDER BY 
    tm.movie_rank;

This query benchmarks string processing by using CTEs to aggregate and rank movies based on their alternative names, cast counts, and average ratings. It then retrieves additional company information for the top-ranked movies that have a significant cast presence. This allows for comprehensive analysis and testing of string operations, aggregations, and joins.
