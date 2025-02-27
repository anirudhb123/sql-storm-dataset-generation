WITH RECURSIVE MovieHierarchy AS (
    -- Level 1: Select top-level movies from the 'title' table
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        1 AS level
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    -- Level 2: Recursive part, linking to sequels or related movies via 'movie_link'
    SELECT 
        ml.linked_movie_id AS movie_id,
        tit.title AS movie_title,
        tit.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title tit ON ml.linked_movie_id = tit.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_title,
    mh.production_year,
    COALESCE(COUNT(DISTINCT c.person_id), 0) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    STRING_AGG(DISTINCT mv.keyword, ', ') AS keywords,
    AVG(mv.info) FILTER (WHERE mv.info_type_id=2) AS avg_rating -- Assuming 'info_type_id=2' corresponds to ratings
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name ak ON ak.person_id = c.person_id
LEFT JOIN 
    movie_keyword mv ON mh.movie_id = mv.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
GROUP BY 
    mh.movie_title, mh.production_year
HAVING 
    COALESCE(AVG(mv.info) FILTER (WHERE mv.info_type_id=2), 0) > 7 -- Assuming a threshold for average rating
ORDER BY 
    mh.production_year DESC, total_cast DESC;
