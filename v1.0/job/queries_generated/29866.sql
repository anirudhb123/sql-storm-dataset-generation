WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM title t
    JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        cast_names,
        keyword_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, keyword_count DESC) AS rank
    FROM RankedMovies
    WHERE production_year >= 2000
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.cast_names,
    fm.keyword_count
FROM FilteredMovies fm
WHERE fm.rank <= 10
ORDER BY fm.rank;

This SQL query provides a comprehensive view of the top 10 movies produced since 2000, ranked by the number of distinct cast members and the number of associated keywords. The query includes several joins to gather relevant data from the `title`, `cast_info`, `aka_name`, and `movie_keyword` tables, calculating the count of unique cast members and keywords while aggregating the cast names into a single string for clarity. The use of common table expressions (CTEs) enhances readability and allows for structured data manipulation.
