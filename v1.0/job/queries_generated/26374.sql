WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        title.id
),
KeywordCount AS (
    SELECT 
        movie_id,
        COUNT(keyword.id) AS keyword_count
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordCount kc ON rm.movie_id = kc.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast_count,
    md.cast_names,
    md.keyword_count
FROM 
    MovieDetails md
WHERE 
    md.cast_count > 5
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC;

This query consists of several parts:

1. **RankedMovies CTE**: This Common Table Expression (CTE) retrieves movies produced between 2000 and 2020, counting the distinct cast members and concatenating their names.

2. **KeywordCount CTE**: This CTE counts the keywords associated with each movie.

3. **MovieDetails CTE**: Combines the information from `RankedMovies` and `KeywordCount` by left joining on `movie_id`, allowing us to retain movies with no keywords.

4. Finally, the main query selects movies that have more than 5 cast members and orders the results first by `production_year` in descending order, and then by `keyword_count`.
