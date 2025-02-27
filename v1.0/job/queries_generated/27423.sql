WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS aka_names,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title AS t
    LEFT JOIN 
        aka_name AS ak ON t.id = ak.id
    LEFT JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    GROUP BY 
        t.id
),
MovieRanking AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY cast_count DESC, production_year ASC) AS movie_rank
    FROM 
        RankedMovies
)
SELECT 
    mr.movie_title,
    mr.production_year,
    mr.aka_names,
    mr.cast_count,
    mr.movie_rank
FROM 
    MovieRanking AS mr
WHERE 
    mr.cast_count > 2 -- Only consider movies with more than 2 cast members
AND 
    mr.production_year BETWEEN 2000 AND 2023 -- Limiting to the 21st century
ORDER BY 
    mr.movie_rank ASC
LIMIT 
    10; -- Fetch top 10 movies by rank
