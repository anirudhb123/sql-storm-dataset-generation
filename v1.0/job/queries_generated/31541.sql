WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.season_nr IS NULL  -- Start from top-level movies (not episodes)
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM title e
    INNER JOIN title s ON e.episode_of_id = s.id
    INNER JOIN MovieHierarchy mh ON s.id = mh.movie_id
),
TopMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(cc.person_id) AS cast_count
    FROM MovieHierarchy m
    LEFT JOIN complete_cast cc ON m.movie_id = cc.movie_id
    GROUP BY m.movie_id, m.title, m.production_year
    HAVING CAST(COUNT(cc.person_id) AS INT) >= 5  -- Keeping movies with 5 or more cast members
),
MoviesWithKeywords AS (
    SELECT 
        t.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword t
    JOIN keyword k ON t.keyword_id = k.id
    GROUP BY t.movie_id
),
MoviesInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mk.keywords
    FROM TopMovies m
    LEFT JOIN MoviesWithKeywords mk ON m.movie_id = mk.movie_id
),
FinalOutput AS (
    SELECT 
        mi.movie_id,
        mi.title,
        mi.production_year,
        COALESCE(mi.keywords, 'No Keywords') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY mi.production_year ORDER BY mi.cast_count DESC) AS rank
    FROM MoviesInfo mi
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.keywords
FROM FinalOutput f
WHERE f.rank <= 10  -- Selecting the top 10 for each production year
ORDER BY f.production_year DESC, f.rank;

This SQL query performs a comprehensive synthesis of data through multiple layers. It starts with a Common Table Expression (CTE) to recursively gather movies and their episodes, then identifies top movies based on the count of cast members. It further aggregates keywords associated with each movie and culminates in a ranked result that retrieves the top ten movies per production year, employing a combination of `LEFT JOIN`, `STRING_AGG`, and window functions.
