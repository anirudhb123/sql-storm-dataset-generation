WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS hierarchy_level,
        NULL AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.hierarchy_level + 1 AS hierarchy_level,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.hierarchy_level,
    coalesce(n.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mc.company_id) FILTER (WHERE mc.company_type_id IS NOT NULL) AS company_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    CASE
        WHEN mh.hierarchy_level > 2 THEN 'Deep'
        ELSE 'Shallow'
    END AS hierarchy_depth,
    ROW_NUMBER() OVER (PARTITION BY mh.hierarchy_level ORDER BY mh.production_year DESC) AS movie_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name n ON n.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    mh.production_year IS NOT NULL 
    AND (n.name IS NOT NULL OR n.name IS NULL)   -- NULL Logic
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.hierarchy_level, n.name 
ORDER BY 
    mh.production_year DESC,
    hierarchy_level ASC,
    movie_rank;

