WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (1, 2)  -- Example for Movies or TV shows, adjust as necessary

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.movie_id AS parent_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mk.keyword,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    AVG(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_note_ratio,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    mh.title AS movie_title,
    mh.production_year AS movie_year,
    RANK() OVER (PARTITION BY mk.id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS keyword_rank
FROM 
    movie_keyword mk
JOIN 
    cast_info ci ON mk.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
WHERE 
    mk.keyword IS NOT NULL 
    AND mh.depth <= 2  -- Limiting depth for hierarchy
GROUP BY 
    mk.id, mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    keyword_rank, actor_count DESC;
