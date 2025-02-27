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
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.aka_names,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC) AS rn
    FROM 
        MovieDetails md
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.aka_names,
    COALESCE(director.name, 'Unknown') AS director_name
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id AND ci.role_id = (SELECT id FROM role_type WHERE role = 'Director')
LEFT JOIN 
    aka_name director ON ci.person_id = director.person_id
WHERE 
    tm.rn <= 5
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
