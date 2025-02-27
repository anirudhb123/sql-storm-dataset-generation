WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        aka_names, 
        keywords,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    tm.keywords
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC; 

This query performs several operations to benchmark string processing:

1. It sets up a Common Table Expression (CTE) called `RankedMovies`, where it joins the `aka_title`, `title`, `cast_info`, and `movie_keyword` tables. This CTE counts distinct cast members and aggregates alternate names and keywords.
   
2. In the second CTE, `TopMovies`, it ranks the movies based on the number of cast members.

3. Finally, it selects the top 10 movies with the highest cast count, including their titles, production years, alternate names, and keywords, and orders them by `cast_count` in descending order.

This showcases a combination of GROUP BY, STRING_AGG for string processing, and ranking functions, all of which are important operations for performance benchmarking in SQL.
