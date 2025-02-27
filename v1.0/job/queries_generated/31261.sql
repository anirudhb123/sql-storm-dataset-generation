WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ccc.movie_id) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(ccc.movie_id) DESC) AS rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ccc ON cc.movie_id = ccc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    tm.title,
    tm.production_year,
    CASE 
        WHEN tm.cast_count > 50 THEN 'Blockbuster'
        WHEN tm.cast_count BETWEEN 20 AND 50 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    ARRAY_AGG(DISTINCT an.name ORDER BY an.name) AS all_cast_names
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name an ON cc.subject_id = an.person_id
WHERE 
    tm.rn <= 10
GROUP BY 
    tm.title, 
    tm.production_year, 
    tm.cast_count
ORDER BY 
    tm.cast_count DESC, 
    tm.title ASC;
