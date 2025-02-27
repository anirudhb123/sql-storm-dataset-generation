WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        company_type,
        actors,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(actors) DESC) AS rn
    FROM 
        MovieDetails
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    company_type,
    actors,
    keywords
FROM 
    TopMovies
WHERE 
    rn <= 5
ORDER BY 
    production_year, company_type, movie_title;

This query benchmarks string processing in several ways:

1. **Aggregation**: It aggregates actor names and keywords for movies released after the year 2000.
2. **Window Functions**: It uses a window function to rank movies based on the number of actors, grouped by production year.
3. **Joins**: It involves multiple joins across various tables, ensuring the query processes a mix of textual data from different sources.
4. **Filtering and Ordering**: It filters the results to show only the top 5 movies per production year, sorted by company type and movie title. 

This query effectively showcases the complexity of string processing with efficient aggregations and joins.
