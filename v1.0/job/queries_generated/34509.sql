WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
),
MovieScores AS (
    SELECT
        m.id AS movie_id,
        COUNT(cc.id) AS cast_count,
        AVG(pi.info::int) AS avg_rating,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info cc ON m.id = cc.movie_id
    LEFT JOIN 
        person_info pi ON cc.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        aka_name p ON cc.person_id = p.person_id
    GROUP BY 
        m.id
    HAVING 
        COUNT(cc.id) > 5
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ms.cast_count,
        ms.avg_rating,
        ms.cast_names,
        RANK() OVER (ORDER BY ms.avg_rating DESC) AS rank
    FROM 
        MovieHierarchy mh
    JOIN 
        MovieScores ms ON mh.movie_id = ms.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.avg_rating,
    tm.cast_names
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.avg_rating DESC, 
    tm.cast_count DESC;
