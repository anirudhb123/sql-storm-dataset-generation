WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        COALESCE(mt.production_year, 0) AS production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS year_rank,
        1 AS depth
    FROM title mt
    WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        lt.title,
        COALESCE(lt.production_year, 0) AS production_year,
        ROW_NUMBER() OVER (PARTITION BY lt.production_year ORDER BY lt.title) AS year_rank,
        mh.depth + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title lt ON ml.linked_movie_id = lt.id
    WHERE mh.depth < 3  -- Limit depth to 3 for performance
),
IndexedMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        year_rank,
        depth,
        COUNT(*) OVER (PARTITION BY production_year) AS total_movies_per_year
    FROM MovieHierarchy
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        year_rank,
        total_movies_per_year
    FROM IndexedMovies
    WHERE year_rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_movies_per_year,
    ARRAY_AGG(DISTINCT ak.name) AS actors,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    COALESCE(SUM(CASE WHEN ci.person_role_id IS NULL THEN 0 ELSE 1 END), 0) AS non_null_role_count
FROM TopMovies tm
LEFT JOIN complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN movie_keyword mk ON mk.movie_id = tm.movie_id
WHERE tm.production_year IS NOT NULL AND tm.production_year < 2023
GROUP BY tm.movie_id, tm.title, tm.production_year, tm.total_movies_per_year
HAVING COUNT(DISTINCT ak.name) > 2 OR SUM(tm.year_rank) IS NULL
ORDER BY tm.production_year DESC, tm.total_movies_per_year ASC, tm.title
LIMIT 100;
