WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title ak
    JOIN 
        title mt ON ak.movie_id = mt.id
    LEFT JOIN 
        cast_info ca ON ca.movie_id = mt.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        aka_names,
        keywords,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    tm.keywords
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10;

This SQL query benchmarks string processing by preparing a ranked list of movies based on the count of distinct cast members involved and aggregates additional data such as alternate names (aka_names) and keywords. The result is limited to the top 10 movies sorted by the highest cast count and most recent production year, showcasing how string processing (like `STRING_AGG`) can be utilized alongside traditional aggregations.
