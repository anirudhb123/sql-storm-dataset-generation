WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Fetch all movies and their immediate casts
    SELECT
        mt.id AS movie_id,
        mt.title,
        ci.person_id,
        0 AS level
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id

    UNION ALL

    -- Recursive case: Fetch movies linked by their respective links
    SELECT
        ml.linked_movie_id,
        at.title,
        ci.person_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        cast_info ci ON at.id = ci.movie_id
)

-- Main query to get detailed cast and movie info
SELECT 
    mh.movie_id,
    mh.title,
    a.name AS actor_name,
    COUNT(DISTINCT mh.person_id) OVER (PARTITION BY mh.movie_id) AS cast_count,
    STRING_AGG(DISTINCT at.title, ', ') FILTER (WHERE at.title IS NOT NULL) AS linked_movies,
    CASE 
        WHEN COUNT(*) FILTER (WHERE ci.note IS NOT NULL) > 0 THEN 'Contains Notes'
        ELSE 'No Notes'
    END AS notes_status
FROM 
    MovieHierarchy mh
JOIN 
    aka_name a ON mh.person_id = a.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    aka_title at ON mh.movie_id = at.movie_id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
WHERE 
    mh.level = 0 -- Only direct movies for hierarchical view
    AND a.name IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, a.name
ORDER BY 
    cast_count DESC, mh.title;
