WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level,
        NULL AS parent_movie_id
    FROM aka_title t 
    WHERE t.production_year > 2000
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        h.level + 1,
        h.movie_id AS parent_movie_id
    FROM aka_title m
    JOIN MovieHierarchy h ON m.episode_of_id = h.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        COALESCE(SUM(mo.info LIKE '%Oscar%' OR mo.info LIKE '%Golden Globe%'), 0) AS awards_count
    FROM MovieHierarchy mh
    LEFT JOIN movie_info mo ON mh.movie_id = mo.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year, mh.level
),
RankedMovies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.level,
        fm.awards_count,
        RANK() OVER (PARTITION BY fm.level ORDER BY fm.awards_count DESC) AS rank_within_level
    FROM FilteredMovies fm
)
SELECT 
    rm.title,
    rm.production_year,
    rm.level,
    (SELECT COUNT(*) 
     FROM RankedMovies rm2 
     WHERE rm2.level = rm.level AND rm2.awards_count > rm.awards_count) AS lower_award_count,
    CASE 
        WHEN rm.awards_count IS NULL THEN 'No Awards'
        WHEN rm.awards_count = 0 THEN 'No Awards'
        ELSE 'Awarded'
    END AS award_status
FROM RankedMovies rm 
LEFT JOIN aka_name an ON an.person_id = (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = rm.movie_id LIMIT 1)
WHERE rm.rank_within_level = 1
AND (rm.production_year BETWEEN 2005 AND 2020 OR rm.production_year IS NULL)
ORDER BY rm.level, rm.production_year DESC
LIMIT 10;

-- This query constructs a hierarchy of movies, filters them based on awards, ranks them, 
-- and includes complex aggregate and window functions while employing NULL logic and 
-- outer joins for added depth.
