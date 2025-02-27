
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ' ORDER BY ak.name) AS aka_names,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title AS t
    LEFT JOIN 
        aka_name AS ak ON t.id = ak.id
    LEFT JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
MovieRanking AS (
    SELECT 
        movie_title,
        production_year,
        aka_names,
        cast_count,
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
    mr.cast_count > 2 
AND 
    mr.production_year BETWEEN 2000 AND 2023 
ORDER BY 
    mr.movie_rank ASC
LIMIT 
    10;
