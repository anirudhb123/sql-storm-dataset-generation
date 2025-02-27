WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title,
        0 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id, 
        at.title AS movie_title,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
)
, TopRatedMovies AS (
    SELECT 
        title.title AS movie_title,
        AVG(mvi.info::numeric) AS avg_rating
    FROM 
        movie_info AS mvi
    JOIN 
        title ON mvi.movie_id = title.id
    WHERE 
        mvi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
    GROUP BY 
        title.title
    HAVING 
        AVG(mvi.info::numeric) >= 8.0
),
MoviesWithCast AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        MovieHierarchy AS mh
    LEFT JOIN 
        complete_cast AS cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mh.movie_id, mh.movie_title
)
SELECT 
    mwc.movie_title,
    mwc.cast_count,
    tr.avg_rating
FROM 
    MoviesWithCast AS mwc
JOIN 
    TopRatedMovies AS tr ON mwc.movie_title = tr.movie_title
WHERE 
    mwc.cast_count > (
        SELECT 
            AVG(cast_count) 
        FROM 
            MoviesWithCast
    )
ORDER BY 
    tr.avg_rating DESC, 
    mwc.cast_count DESC;
