WITH MovieDetails AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COUNT(DISTINCT c.id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        MAX(mh.info) FILTER (WHERE mh.info_type_id = 1) AS original_language,
        COALESCE(SUM(mk.keyword IS NOT NULL)::integer, 0) AS keyword_count
    FROM aka_title mt
    LEFT JOIN complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN movie_info mh ON mt.id = mh.movie_id
    GROUP BY mt.id
),
RankedMovies AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS actor_rank
    FROM MovieDetails
),
FilteredMovies AS (
    SELECT
        *,
        CASE 
            WHEN actor_count > 5 THEN 'Ensemble Cast'
            WHEN actor_count BETWEEN 3 AND 5 THEN 'Moderate Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM RankedMovies
    WHERE original_language IS NOT NULL
      AND NOT (production_year IS NULL OR production_year < 2000) -- Only movies from year 2000 onwards
)

SELECT
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_count,
    f.actors,
    f.cast_size,
    ARRAY_LENGTH(STRING_TO_ARRAY(f.actors, ', '), 1) AS actor_list_size,
    CASE 
        WHEN f.cast_size = 'Small Cast' THEN 'Low Engagement'
        ELSE 'High Engagement'
    END AS engagement_level
FROM FilteredMovies f
WHERE f.actor_rank <= 3  -- Top 3 movies by actor count per year
  AND f.keyword_count > 1  -- Only films with more than 1 associated keyword
ORDER BY f.production_year, f.actor_count DESC;

-- Edge case handling for NULL keywords and actors
SELECT f.*, 
       CASE 
           WHEN f.keyword_count IS NULL THEN 'No Keywords Found' 
           ELSE 'Has Keywords' 
       END AS keyword_status,
       CASE
           WHEN actor_count IS NULL THEN 'Unknown Actor Count'
           ELSE 'Known Actor Count'
       END AS actor_count_status
FROM FilteredMovies f
WHERE f.actor_rank <= 10;  -- Further analysis of the top 10 movies 
