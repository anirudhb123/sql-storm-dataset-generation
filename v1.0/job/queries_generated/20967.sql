WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        NULL AS parent_movie
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1  -- Let's consider the first kind, which could represent a specific genre
    UNION ALL
    SELECT 
        linked_movie.id AS movie_id,
        linked_movie.title,
        linked_movie.production_year,
        mh.level + 1,
        mh.movie_id AS parent_movie
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title linked_movie ON ml.linked_movie_id = linked_movie.id
    WHERE 
        mh.level < 3  -- Limit hierarchy depth to avoid excessive recursion
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.level AS movie_level,
    CASE
        WHEN ak.surname_pcode IS NULL THEN 'Unknown Surname Code' 
        ELSE ak.surname_pcode 
    END AS surname_code, 
    COALESCE(CAST(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS INTEGER), 0) AS total_cast_with_notes,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY mh.production_year DESC) AS role_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND mh.production_year > 2000 
    AND (ci.nr_order IS NULL OR ci.nr_order > 0)
GROUP BY 
    ak.id, at.title, mh.level
HAVING 
    COUNT(DISTINCT mk.keyword) > 3 
ORDER BY 
    role_rank, ak.name;
