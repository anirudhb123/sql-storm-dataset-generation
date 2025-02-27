WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        md.title AS movie_title,
        0 AS level,
        md.production_year,
        NULL::text AS parent_movie_title
    FROM 
        aka_title mt
    JOIN 
        title md ON mt.movie_id = md.id
    WHERE 
        md.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mb.title,
        level + 1,
        mb.production_year,
        mh.movie_title
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        title mb ON ml.linked_movie_id = mb.id
)
SELECT 
    mh.movie_title,
    mh.production_year,
    mh.level,
    COALESCE(ka.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT cc.id) AS total_cast,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ka ON ci.person_id = ka.person_id
LEFT JOIN 
    movie_keyword mw ON mh.movie_id = mw.movie_id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
WHERE 
    mh.level = 0  -- Only the top-level movies
GROUP BY 
    mh.movie_title, mh.production_year, mh.level, ka.name
ORDER BY 
    mh.production_year DESC, mh.movie_title;
