WITH RecursiveMovieTitles AS (
    SELECT t.id, t.title, t.production_year,
           ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
MovieCastInfo AS (
    SELECT c.movie_id, COUNT(DISTINCT c.person_id) AS cast_size
    FROM cast_info c
    GROUP BY c.movie_id
),
TopMoviesByCast AS (
    SELECT r.title, r.production_year, mc.cast_size
    FROM RecursiveMovieTitles r
    LEFT JOIN MovieCastInfo mc ON r.id = mc.movie_id
    WHERE mc.cast_size IS NOT NULL
    ORDER BY mc.cast_size DESC
    LIMIT 10
),
MovieKeywordRank AS (
    SELECT m.id AS movie_id, k.keyword, 
           RANK() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM aka_title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE m.production_year >= 2000
)
SELECT DISTINCT t.title AS movie_title,
                t.production_year,
                COALESCE(mki.keyword, 'No Keywords') AS keyword,
                CASE 
                    WHEN mki.keyword_rank IS NULL THEN 'Non-Highlighted'
                    WHEN mki.keyword_rank <= 5 THEN 'Highlighted'
                    ELSE 'Other'
                END AS category,
                CASE 
                    WHEN COALESCE(cm.cast_size, 0) > 5 THEN 'Large Cast'
                    ELSE 'Small Cast'
                END AS cast_category
FROM TopMoviesByCast t
LEFT JOIN MovieKeywordRank mki ON t.title = mki.movie_id
LEFT JOIN MovieCastInfo cm ON t.production_year = cm.movie_id
WHERE t.production_year BETWEEN 2000 AND 2023
AND (
    mki.keyword IS NOT NULL OR
    t.production_year IS NULL
)
ORDER BY t.production_year DESC, t.title;

### Explanation
- **CTEs Usage**: The query uses multiple Common Table Expressions (CTEs) to break down the complex logic into manageable parts. The first CTE (`RecursiveMovieTitles`) gathers movie titles and ranks them by production year. The second (`MovieCastInfo`) summarizes cast sizes per movie, and the third (`TopMoviesByCast`) fetches the top 10 movies based on their cast size.
  
- **Window Functions**: These are utilized to rank movie titles by alphabetical order (`ROW_NUMBER`) and keywords associated with each movie (`RANK`).

- **Outer Joins**: Use of `LEFT JOIN` allows for capturing movies with or without keywords and cast size availability.

- **Complex Logic**: Predicate logic is introduced with COALESCE for handling NULLs, and additional CASE statements categorize movies into highlighted and non-highlighted based on their keyword ranks and cast sizes.

- **Overlapping Conditions**: The use of varying categories based on the conditions in the CASE statements illustrates corner cases that can arise in movie data aggregations.

- **String Expressions**: The output leverages the strings `No Keywords` and `Non-Highlighted` providing clarity on the absence/availability of certain data attributes.

This query structure ensures performance benchmarking across various attributes and establishes solid visibility into the dataset while navigating complex SQL semantics.
