
WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        t.episode_of_id,
        1 AS level
    FROM title t
    WHERE t.episode_of_id IS NULL  
    UNION ALL
    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.episode_of_id,
        mh.level + 1
    FROM title t
    INNER JOIN MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
CastStatistics AS (
    
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        AVG(m.production_year) AS avg_production_year
    FROM cast_info c
    JOIN title m ON c.movie_id = m.id
    GROUP BY c.person_id
),
MoviesWithKeywords AS (
    
    SELECT 
        m.id AS movie_id,
        m.title,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id, m.title
),
FullMovieInfo AS (
    
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.level,
        COALESCE(cs.total_movies, 0) AS total_roles,
        COALESCE(cs.avg_production_year, 0) AS avg_year,
        COALESCE(mkw.keywords, 'None') AS keywords
    FROM MovieHierarchy mh
    LEFT JOIN CastStatistics cs ON mh.movie_id = cs.person_id
    LEFT JOIN MoviesWithKeywords mkw ON mh.movie_id = mkw.movie_id
)
SELECT 
    f.movie_id,
    f.movie_title,
    f.production_year,
    f.level,
    f.total_roles,
    f.avg_year,
    f.keywords
FROM FullMovieInfo f
WHERE f.production_year > 2000
  AND f.total_roles > 0
ORDER BY f.production_year DESC, f.total_roles DESC
LIMIT 10;
