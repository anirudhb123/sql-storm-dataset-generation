WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(ak.name, 'Unknown') AS actor_name,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ak.name, 'Unknown') AS actor_name,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON mt.id = ml.linked_movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
)
SELECT 
    mh.title,
    mh.production_year,
    STRING_AGG(DISTINCT mh.actor_name, ', ') AS actors,
    COUNT(DISTINCT mh.level) AS depth
FROM 
    MovieHierarchy mh
GROUP BY 
    mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT mh.actor_name) >= 3
ORDER BY 
    mh.production_year DESC;

WITH MovieInfo AS (
    SELECT 
        mt.title,
        mt.production_year,
        mi.info
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mi ON mi.movie_id = mt.id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(mi.info, 'No Info Available') AS plot_description,
    COUNT(c.id) AS cast_count
FROM 
    MovieInfo m
LEFT JOIN 
    complete_cast c ON c.movie_id = m.movie_id
GROUP BY 
    m.title, m.production_year, mi.info
HAVING 
    COUNT(c.id) > 5
ORDER BY 
    m.production_year ASC;

SELECT 
    kt.kind AS keyword,
    COUNT(DISTINCT mt.id) AS movie_count,
    AVG(COALESCE(mi.info::float, 0)) AS average_info_type_count
FROM 
    keyword kt
JOIN 
    movie_keyword mk ON mk.keyword_id = kt.id
JOIN 
    aka_title mt ON mt.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mt.id
GROUP BY 
    kt.kind
HAVING 
    COUNT(DISTINCT mt.id) > 10
ORDER BY 
    movie_count DESC;
