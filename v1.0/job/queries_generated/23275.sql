WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY RAND()) AS random_rank
    FROM title t
    WHERE t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ExpandedCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        cc.kind AS cast_type,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN comp_cast_type cc ON c.person_role_id = cc.id
    WHERE cc.kind IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS all_keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
FilteredMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        ec.actor_name,
        ec.cast_type,
        mk.all_keywords,
        COUNT(ec.actor_name) OVER (PARTITION BY mt.id) AS total_actors
    FROM RankedTitles mt
    LEFT JOIN ExpandedCast ec ON mt.production_year = ec.movie_id
    LEFT JOIN MovieKeywords mk ON mt.id = mk.movie_id
    WHERE mt.random_rank <= 5  -- Randomly select up to 5 titles per year
)
SELECT 
    COALESCE(fm.title, 'Unknown Title') AS Title,
    COALESCE(fm.production_year, 0) AS Production_Year,
    COALESCE(fm.actor_name, 'Unknown Actor') AS Actor,
    COALESCE(fm.cast_type, 'Unknown Role') AS Role,
    COALESCE(fm.all_keywords, 'No Keywords') AS Keywords,
    (CASE 
        WHEN fm.total_actors > 0 THEN CONCAT(fm.total_actors, ' actors')
        ELSE 'No actors in this movie'
    END) AS Actor_Info
FROM FilteredMovies fm
ORDER BY fm.production_year DESC, fm.total_actors DESC
LIMIT 50;

This query demonstrates a variety of SQL constructs:
- CTEs (`WITH` clause) are used to break the query down into manageable pieces: `RankedTitles`, `ExpandedCast`, `MovieKeywords`, and `FilteredMovies`.
- It includes a `ROW_NUMBER()` window function to generate unique ranking for movies and cast.
- The use of `LEFT JOIN` allows for capturing data even if there are no actors for some titles.
- `STRING_AGG` aggregates keywords related to movies.
- Conditional logic is utilized through the `CASE` statement to provide meaningful output even when values may be null or missing.
- `COALESCE` handles null logic for more reliable output formatting.
- The randomness introduced with `RAND()` during ranking adds a unique element to the results, ensuring different titles may be selected each time the query runs.

This comprehensive query should provide a thorough performance benchmark due to its complexity and multiple SQL features utilized.
