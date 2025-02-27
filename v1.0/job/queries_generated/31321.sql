WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        COALESCE(mt.season_nr, 0) AS season_nr, 
        COALESCE(mt.episode_nr, 0) AS episode_nr, 
        1 AS level
    FROM title mt
    WHERE mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        COALESCE(mt.season_nr, 0), 
        COALESCE(mt.episode_nr, 0), 
        mh.level + 1
    FROM title mt
    JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
AggregatedPerformance AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.season_nr,
        mh.episode_nr,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT COALESCE(mc.company_id, 0)) AS total_companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        AVG(CASE WHEN mi.info_type_id IS NOT NULL THEN LENGTH(mi.info) END) AS avg_info_length
    FROM MovieHierarchy mh
    LEFT JOIN cast_info c ON mh.movie_id = c.movie_id
    LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id
    GROUP BY mh.movie_id, mh.title, mh.season_nr, mh.episode_nr
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        season_nr,
        episode_nr,
        total_cast,
        total_companies,
        keywords,
        avg_info_length,
        RANK() OVER (ORDER BY total_cast DESC, total_companies DESC) AS rank
    FROM AggregatedPerformance
)
SELECT 
    tm.movie_id, 
    tm.title, 
    tm.season_nr, 
    tm.episode_nr,
    tm.total_cast,
    tm.total_companies,
    tm.keywords,
    tm.avg_info_length
FROM TopMovies tm
WHERE tm.rank <= 10 
ORDER BY tm.total_cast DESC, tm.total_companies DESC;
