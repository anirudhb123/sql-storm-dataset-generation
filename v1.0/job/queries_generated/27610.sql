WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT k.id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keyword_list
    FROM 
        aka_title t
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
        keyword_count,
        keyword_list,
        RANK() OVER (ORDER BY keyword_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
),
CastDetails AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword_count,
    tm.keyword_list,
    cd.cast_names,
    cd.cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.movie_id = cd.movie_id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.keyword_count DESC;

This SQL query performs the following operations:

1. `RankedMovies`: It aggregates movie information from the `aka_title` table and counts the distinct keywords associated with each movie by joining with `movie_keyword` and `keyword`. It uses the `STRING_AGG` function to create a concatenated list of unique keywords for each movie.

2. `TopMovies`: It filters the movies to include only those produced after the year 2000 and ranks them based on the count of distinct keywords using the `RANK()` function.

3. `CastDetails`: It gathers information about the cast for each movie by joining the `cast_info` with `aka_name` to retrieve the names of the cast members. It counts the number of distinct cast members associated with each movie and aggregates their names.

4. The final `SELECT` statement retrieves the top 10 movies based on the number of keywords, along with their production year, keyword count, keyword list, cast names, and total cast count. It sorts the results in descending order of keyword count.
