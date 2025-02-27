WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS TEXT) AS hierarchy_path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Starting with movies from the year 2000 onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.level + 1,
        CAST(mh.hierarchy_path || ' -> ' || a.title AS TEXT)
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.hierarchy_path,
    COALESCE(ki.keyword, 'No Keyword') AS keyword,
    COUNT(*) OVER (PARTITION BY mh.movie_id) AS cast_count,
    ARRAY_AGG(DISTINCT ak.name ORDER BY ak.name) AS actor_names,
    AVG(PI.number_of_movies) AS average_movies_per_actor
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN (
    SELECT 
        person_id, 
        COUNT(DISTINCT movie_id) AS number_of_movies 
    FROM 
        cast_info 
    GROUP BY 
        person_id
) PI ON ci.person_id = PI.person_id
WHERE 
    mh.production_year IS NOT NULL  -- Ensuring the production year is valid
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.hierarchy_path, ki.keyword
HAVING 
    COUNT(DISTINCT ak.name) >= 2  -- Only include movies with at least 2 distinct actors
ORDER BY 
    mh.production_year DESC, mh.level, mh.title;
