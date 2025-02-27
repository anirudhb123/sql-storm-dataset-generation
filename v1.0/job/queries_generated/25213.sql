WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ak.imdb_index AS actor_imdb_index,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        aka_title t
    INNER JOIN 
        cast_info ci ON t.id = ci.movie_id
    INNER JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year IS NOT NULL
),
KeyWordCounts AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title
),
TopKeywords AS (
    SELECT 
        movie_id,
        movie_title,
        keyword_count,
        RANK() OVER (ORDER BY keyword_count DESC) AS rank
    FROM 
        KeyWordCounts
),
FinalResults AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_name,
        tk.keyword_count
    FROM 
        RankedMovies rm
    JOIN 
        TopKeywords tk ON rm.year_rank <= 5 AND rm.movie_title = tk.movie_title -- Top 5 Movies with Most Keywords each Year
)

SELECT 
    fr.movie_title,
    fr.production_year,
    fr.actor_name,
    fr.keyword_count
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.keyword_count DESC
LIMIT 10;
This SQL query benchmarks string processing across actor names, movie titles, and keyword occurrences while leveraging CTEs (Common Table Expressions) to create organized and modular code. The first CTE (`RankedMovies`) ranks movies by production year and title; the second CTE (`KeyWordCounts`) aggregates keyword counts for each movie; the third CTE (`TopKeywords`) ranks the movies by their keyword counts, and the `FinalResults` CTE combines the results to showcase the top movies with the most keywords from the latest productions. Finally, the main SELECT statement fetches the top 10 records from the compiled results.
