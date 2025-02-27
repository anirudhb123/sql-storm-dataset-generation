WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(mt2.title, 'N/A') AS linked_movie_title,
        COALESCE(mt2.production_year, 0) AS linked_movie_year,
        1 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    LEFT JOIN 
        aka_title mt2 ON ml.linked_movie_id = mt2.id
    
    UNION ALL
    
    SELECT 
        mh.movie_title,
        mh.production_year,
        COALESCE(mt2.title, 'N/A'),
        COALESCE(mt2.production_year, 0),
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_link ml ON mh.linked_movie_title = (SELECT mt.title FROM aka_title mt WHERE mh.depth = 1 LIMIT 1)
    LEFT JOIN 
        aka_title mt2 ON ml.linked_movie_id = mt2.id
    WHERE 
        mh.depth < 5
), 
CastAggregate AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    h.movie_title,
    h.production_year,
    h.linked_movie_title,
    h.linked_movie_year,
    ca.total_cast,
    ca.cast_names,
    ROW_NUMBER() OVER (PARTITION BY h.movie_title ORDER BY h.depth DESC) AS rank
FROM 
    MovieHierarchy h
LEFT JOIN 
    CastAggregate ca ON h.linked_movie_title = ca.movie_id
WHERE 
    h.production_year >= 2000
    AND (h.linked_movie_title IS NOT NULL OR h.linked_movie_year > 0)
ORDER BY 
    h.production_year DESC, h.depth ASC;

