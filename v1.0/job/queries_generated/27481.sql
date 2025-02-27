WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        aka_names,
        keywords,
        cast_count,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_within_year
    FROM 
        RankedMovies
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    aka_names,
    keywords,
    cast_count
FROM 
    FilteredMovies
WHERE 
    rank_within_year <= 5
ORDER BY 
    production_year DESC, cast_count DESC;
