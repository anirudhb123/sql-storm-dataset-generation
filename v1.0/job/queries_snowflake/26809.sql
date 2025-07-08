
WITH RankedMovies AS (
    SELECT 
        ak.id AS aka_id,
        ak.name AS aka_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER(PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        ak.name ILIKE '%Smith%'  
),
TopRankedMovies AS (
    SELECT 
        aka_id,
        aka_name,
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5  
),
AggregatedResults AS (
    SELECT 
        aka_name,
        COUNT(*) AS movie_count,
        LISTAGG(movie_title, '; ') WITHIN GROUP (ORDER BY production_year) AS all_movies,
        MIN(production_year) AS first_movie_year,
        MAX(production_year) AS last_movie_year
    FROM 
        TopRankedMovies
    GROUP BY 
        aka_name
)
SELECT 
    aka_name,
    movie_count,
    all_movies,
    first_movie_year,
    last_movie_year,
    (last_movie_year - first_movie_year) AS year_range
FROM 
    AggregatedResults
ORDER BY 
    year_range DESC;
