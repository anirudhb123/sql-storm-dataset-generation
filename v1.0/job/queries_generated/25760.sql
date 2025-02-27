WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        COUNT(DISTINCT c.person_id) AS cast_count,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    aka_names,
    cast_count,
    keywords
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC;

This SQL query benchmarks string processing capabilities by aggregating movie details with a focus on Alternate Titles (aka names), keywords, and actor counts from various related tables. The main goal is to fetch the top 10 movies (based on cast count) produced after the year 2000, showcasing the use of advanced string processing features such as concatenation and ranking.
