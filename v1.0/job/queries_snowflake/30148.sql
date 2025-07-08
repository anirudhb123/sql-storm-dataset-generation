
WITH MovieHierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           0 AS level,
           ARRAY_CONSTRUCT(mt.id) AS path
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT a.id AS movie_id, 
           a.title, 
           a.production_year, 
           mh.level + 1,
           ARRAY_CAT(mh.path, ARRAY_CONSTRUCT(a.id))
    FROM aka_title a
    JOIN MovieHierarchy mh ON a.episode_of_id = mh.movie_id
),
MovieStats AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_with_notes,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        m.production_year
    FROM aka_title m
    LEFT JOIN cast_info c ON m.id = c.movie_id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        ms.movie_id, 
        ms.title, 
        ms.total_cast, 
        ms.avg_with_notes,
        ms.keywords,
        ROW_NUMBER() OVER (PARTITION BY ms.production_year ORDER BY ms.total_cast DESC) AS rank
    FROM MovieStats ms
    WHERE ms.total_cast > 0
),
RankedMovies AS (
    SELECT 
        th.movie_id,
        th.title,
        th.total_cast,
        th.avg_with_notes,
        th.keywords,
        th.rank,
        CASE 
            WHEN th.rank <= 5 THEN 'Top 5'
            ELSE 'Others' 
        END AS category
    FROM TopMovies th
)
SELECT 
    rm.title,
    rm.total_cast,
    rm.avg_with_notes,
    rm.keywords,
    mh.level AS hierarchy_level,
    CASE
        WHEN mh.movie_id IS NOT NULL THEN 'Has Episodes'
        ELSE 'Standalone Movie'
    END AS movie_type
FROM RankedMovies rm
LEFT JOIN MovieHierarchy mh ON rm.movie_id = mh.movie_id
WHERE rm.category = 'Top 5'
ORDER BY rm.total_cast DESC, rm.title;
