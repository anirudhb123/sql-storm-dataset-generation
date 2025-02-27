WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year > 2000 -- Focus on movies produced after 2000
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.movie_keyword,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank = 1 -- Select the top movie for each keyword
),
KeywordStats AS (
    SELECT 
        movie_keyword,
        COUNT(movie_title) AS movie_count,
        AVG(cast_count) AS average_cast_size
    FROM 
        FilteredMovies
    GROUP BY 
        movie_keyword
)
SELECT 
    ks.movie_keyword,
    ks.movie_count,
    ks.average_cast_size
FROM 
    KeywordStats ks
ORDER BY 
    ks.movie_count DESC, ks.average_cast_size DESC
LIMIT 10; -- Limit to top 10 keywords

This query performs a series of common table expressions (CTEs) to benchmark the string processing capabilities of the database. It ranks movies by the number of cast members associated with each movie, filtering for movies produced after the year 2000. Subsequently, it identifies the most prominent movie associated with each keyword and aggregates statistics, including the count of movies and the average cast size for each keyword. Finally, it selects the top 10 keywords based on the number of unique movies associated with them, also ordering the results by both movie count and average cast size for more insight.
