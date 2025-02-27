
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.movie_id
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ci.id) AS cast_count
    FROM 
        MovieHierarchy mh
    JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        mh.production_year >= 2000 
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(ci.id) > 5
),
MovieKeywordCounts AS (
    SELECT 
        mt.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    tm.cast_count,
    CASE 
        WHEN COALESCE(mkc.keyword_count, 0) > 0 AND tm.cast_count > 10 THEN 'Popular with Keywords'
        WHEN COALESCE(mkc.keyword_count, 0) = 0 AND tm.cast_count > 10 THEN 'Popular without Keywords'
        ELSE 'Less Popular'
    END AS popularity_indicator,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywordCounts mkc ON tm.movie_id = mkc.movie_id
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, mkc.keyword_count, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
