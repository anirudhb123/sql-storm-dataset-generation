WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
    JOIN 
        movie_companies mc ON ak.movie_id = mc.movie_id
    JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    JOIN 
        title m ON m.id = ak.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        aka_names,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, production_year ASC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    k.keyword AS movie_keyword
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;

This SQL query does the following:

1. **Common Table Expression (CTE) `RankedMovies`:** It aggregates data about movies, counting distinct actors and joining information from the `aka_title`, `movie_companies`, `cast_info`, and `title` tables. It builds a summary that includes the movie's ID, title, production year, the number of actors in the cast, and any alternate names (aka names).

2. **Second CTE `TopMovies`:** This CTE ranks the movies based on their cast count and production year. The movies with higher cast counts come first, and in the case of ties, newer movies are prioritized.

3. **Final Selection:** The query retrieves the top 10 movies based on the rank calculated in the previous CTE, including their title, production year, cast count, aka names, and any associated keywords from the `keyword` table.

4. **Ordering:** The final output is ordered by the rank of movies. 

The combination of these elements makes the query both efficient and illustrative for string processing and aggregation within the context of movie data.
