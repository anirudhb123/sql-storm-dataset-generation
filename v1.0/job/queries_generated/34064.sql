WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all movies with their IDs
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    -- Recursive case: Join with movie_link to get connections
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mh.movie_id) AS avg_casting,
    STRING_AGG(DISTINCT ak.name, ', ') AS known_actors,
    COUNT(DISTINCT mk.keyword) AS total_keywords,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Unknown Year'
        WHEN mh.production_year = 2000 THEN 'Year 2000'
        ELSE 'Post 2000'
    END AS year_category
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth
ORDER BY 
    mh.depth, avg_casting DESC, mh.production_year;
