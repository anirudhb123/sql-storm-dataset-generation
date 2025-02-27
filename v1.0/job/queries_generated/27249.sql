WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        string_agg(DISTINCT a.name, ', ') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rnk
    FROM 
        aka_title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
        AND k.keyword IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        cast_names
    FROM 
        RankedMovies
    WHERE 
        rnk <= 5  -- Get top 5 movies for each keyword
)
SELECT 
    movie_title,
    production_year,
    movie_keyword,
    cast_names,
    COUNT(*) OVER (PARTITION BY movie_keyword) AS keyword_frequency
FROM 
    TopMovies
ORDER BY 
    movie_keyword, production_year DESC;

This SQL query does the following:
1. It ranks movies based on their production year and aggregates the names of the cast members into a single string for each movie.
2. It limits the results to retrieve the top 5 movies per keyword.
3. Finally, it returns a comprehensive selection showing movie titles, the year of production, keywords, cast names, and a frequency count of how many times each keyword appears among the top movies.
