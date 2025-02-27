WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mt.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
)

SELECT 
    mh.movie_id,
    mh.title AS movie_title,
    mh.production_year,
    COALESCE(string_agg(DISTINCT ak.name ORDER BY ak.name), 'No Cast') AS cast_names,
    COUNT(DISTINCT ci.id) AS total_cast,
    COUNT(DISTINCT mk.keyword) FILTER (WHERE mk.keyword IS NOT NULL) AS total_keywords,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes,
    AVG(season_info.season) OVER (PARTITION BY mh.movie_id ORDER BY mh.production_year) AS average_season_numbers,
    CASE 
        WHEN COUNT(DISTINCT ci.id) = 0 THEN 'Unknown Cast'
        WHEN COUNT(DISTINCT ci.id) > 10 THEN 'Large Cast'
        ELSE 'Regular Cast'
    END AS cast_size_category,
    LEAST(COALESCE(NULLIF(MAX(m.movie_info_type_id), 0), 999), 999) AS lowest_info_type
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN (
    SELECT 
        movie_id,
        season_nr AS season
    FROM 
        aka_title 
    WHERE 
        kind_id = (SELECT id FROM kind_type WHERE kind = 'series')
) season_info ON season_info.movie_id = mh.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, total_cast DESC, mh.movie_id
LIMIT 100
OFFSET 0;

