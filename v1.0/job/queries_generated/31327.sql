WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level,
        NULL AS parent_title
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- Start with top-level movies (no parent)
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        et.kind_id,
        mh.level + 1,
        mh.title AS parent_title
    FROM 
        aka_title et
    INNER JOIN 
        MovieHierarchy mh ON mh.movie_id = et.episode_of_id
)

SELECT 
    mh.movie_id,
    mh.title AS movie_title,
    mh.production_year,
    mh.level,
    mh.parent_title,
    ARRAY_AGG(DISTINCT ak.name) AS cast_members,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
WHERE
    mh.production_year >= 2000   -- Filter for movies produced from the year 2000 onwards
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.parent_title
HAVING 
    COUNT(DISTINCT ci.person_id) > 3    -- Only include movies with more than 3 cast members
ORDER BY 
    mh.production_year DESC, mh.level, mh.title;
