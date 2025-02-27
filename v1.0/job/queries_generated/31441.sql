WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth,
        COUNT(DISTINCT cc.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY mh.production_year DESC) AS rank_within_depth
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.depth
),
PopularMovies AS (
    SELECT 
        rm.*,
        COALESCE(NULLIF(mk.keyword, ''), 'No Keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.num_cast > (
            SELECT 
                AVG(num_cast) 
            FROM 
                RankedMovies
        )
)
SELECT 
    pm.title AS Movie_Title,
    pm.production_year AS Production_Year,
    pm.depth AS Depth,
    pm.num_cast AS Number_of_Cast,
    STRING_AGG(DISTINCT pm.keywords, ', ') AS Keywords
FROM 
    PopularMovies pm
GROUP BY 
    pm.movie_id, pm.title, pm.production_year, pm.depth, pm.num_cast
ORDER BY 
    pm.depth, pm.production_year DESC;

