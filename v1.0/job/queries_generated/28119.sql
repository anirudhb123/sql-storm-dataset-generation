WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT mk.keyword) AS total_keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
), 
MovieRanks AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        aka_names,
        total_cast,
        total_keywords,
        RANK() OVER (ORDER BY total_cast DESC, production_year ASC) AS cast_rank,
        RANK() OVER (ORDER BY total_keywords DESC, production_year ASC) AS keyword_rank
    FROM 
        RankedMovies
)
SELECT 
    mr.movie_id,
    mr.movie_title,
    mr.production_year,
    mr.aka_names,
    mr.total_cast,
    mr.total_keywords,
    mr.cast_rank,
    mr.keyword_rank,
    p.name AS main_actor
FROM 
    MovieRanks mr
LEFT JOIN 
    cast_info ci ON mr.movie_id = ci.movie_id
LEFT JOIN 
    name p ON p.id = ci.person_id
WHERE 
    ci.nr_order = 1
ORDER BY 
    mr.cast_rank, mr.keyword_rank;
