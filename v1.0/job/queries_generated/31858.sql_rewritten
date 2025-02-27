WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, mt.episode_of_id, 1 AS level
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT mt.id, mt.title, mt.production_year, mt.episode_of_id, mh.level + 1
    FROM aka_title mt
    JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
PersonRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        rt.role,
        COUNT(*) OVER (PARTITION BY ci.person_id, rt.role) AS role_count
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT p.person_id) AS total_cast,
        mw.keywords
    FROM MovieHierarchy mh
    LEFT JOIN PersonRoles p ON mh.movie_id = p.movie_id
    LEFT JOIN MoviesWithKeywords mw ON mh.movie_id = mw.movie_id
    WHERE mh.production_year >= 2000
    GROUP BY mh.movie_id, mh.title, mh.production_year, mw.keywords
    ORDER BY total_cast DESC
    LIMIT 10
)
SELECT 
    tm.title, 
    tm.production_year, 
    COALESCE(tm.keywords, 'No Keywords') AS keywords, 
    COALESCE(NULLIF(TRIM(CAST(tm.total_cast AS TEXT)), '0'), 'No Cast Info') AS cast_info
FROM TopMovies tm
ORDER BY tm.production_year DESC;