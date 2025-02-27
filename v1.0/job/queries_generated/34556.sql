WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ac.name, ', ') AS cast_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ac ON ci.person_id = ac.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
), 
MovieInfo AS (
    SELECT 
        mt.movie_id,
        COALESCE(mi.info, 'No info available') AS info
    FROM 
        MovieStats mt
    LEFT JOIN 
        movie_info mi ON mt.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genres')
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.total_cast,
    ms.cast_names,
    mi.info
FROM 
    MovieStats ms
LEFT JOIN 
    MovieInfo mi ON ms.movie_id = mi.movie_id
WHERE 
    (ms.production_year BETWEEN 2000 AND 2020)
    AND (ms.total_cast > 5 OR ms.cast_names LIKE '%Tom Hanks%')
ORDER BY 
    ms.production_year DESC, ms.total_cast DESC;
