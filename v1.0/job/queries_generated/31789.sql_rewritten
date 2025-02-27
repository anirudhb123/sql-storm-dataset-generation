WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        1 AS level
    FROM title m
    WHERE m.episode_of_id IS NULL  
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        h.level + 1
    FROM title e
    JOIN MovieHierarchy h ON e.episode_of_id = h.movie_id  
),
CastStatistics AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM cast_info c
    JOIN aka_name ak ON ak.person_id = c.person_id
    GROUP BY c.movie_id
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mn.id) AS company_count
    FROM movie_companies mc
    JOIN company_name mn ON mn.id = mc.company_id
    GROUP BY mc.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cs.total_cast_count, 0) AS cast_count,
        COALESCE(cmp.company_count, 0) AS company_count,
        mh.level
    FROM MovieHierarchy mh
    LEFT JOIN CastStatistics cs ON mh.movie_id = cs.movie_id
    LEFT JOIN CompanyStats cmp ON mh.movie_id = cmp.movie_id
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.company_count,
    CASE 
        WHEN tm.company_count > 5 THEN 'High'
        WHEN tm.company_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS company_involvement,
    CASE 
        WHEN tm.cast_count > 20 THEN 'Ensemble'
        WHEN tm.cast_count BETWEEN 10 AND 20 THEN 'Moderate'
        ELSE 'Small'
    END AS cast_size,
    ROW_NUMBER() OVER (ORDER BY tm.production_year DESC, tm.cast_count DESC) AS ranking
FROM TopMovies tm
WHERE tm.level = 1  
ORDER BY ranking;