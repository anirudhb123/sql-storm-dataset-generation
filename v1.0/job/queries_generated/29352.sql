WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY keyword ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.keyword,
    f.cast_count
FROM 
    FilteredMovies f
WHERE 
    f.rank <= 5
ORDER BY 
    f.keyword, f.cast_count DESC;

This query performs benchmarking on string processing by selecting the top 5 movies for each keyword based on the number of actors cast in them, while demonstrating usage of common table expressions (CTEs), joins, aggregations, and window functions.
