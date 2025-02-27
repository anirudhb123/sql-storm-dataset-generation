WITH RECURSIVE MovieHierarchy AS (
    -- Starting point, select all movies with their titles and years
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    -- Recursive part: join with linked movies to build hierarchy
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.hierarchy_level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT cc.person_id) AS total_cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank_by_cast_count,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent' 
    END AS movie_category
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
WHERE 
    mh.hierarchy_level <= 2
    AND ak.name IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT cc.person_id) > 0
ORDER BY 
    rank_by_cast_count, mh.production_year DESC;

-- Note: This query explores movies, their cast, and groups them by production year
-- while recursively considering linked movies. It categorizes the movies 
-- into 'Classic', 'Modern' and 'Recent' based on their production year.
