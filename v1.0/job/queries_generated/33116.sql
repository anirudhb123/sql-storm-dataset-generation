WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mk.title,
        mk.production_year,
        mh.level + 1,
        mk.episode_of_id
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mk ON ml.linked_movie_id = mk.id
    WHERE 
        mh.level < 5  -- Limit to 5 levels deep
)

SELECT 
    ah.name AS actor_name,
    at.title AS movie_title,
    COUNT(DISTINCT mc.id) AS company_count,
    SUM(CASE WHEN mp.info LIKE '%Award%' THEN 1 ELSE 0 END) AS awards_count,
    ROW_NUMBER() OVER (PARTITION BY ah.name ORDER BY ah.name) AS actor_rank,
    mh.level AS movie_level
FROM 
    aka_name ah
JOIN 
    cast_info ci ON ah.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    movie_info mp ON at.id = mp.movie_id AND mp.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
WHERE 
    ah.name IS NOT NULL
    AND at.production_year BETWEEN 2000 AND 2020
    AND (mc.company_type_id IS NULL OR mc.company_type_id != (SELECT id FROM company_type WHERE kind = 'Distributor'))
GROUP BY 
    ah.name, at.title, mh.level
ORDER BY 
    awards_count DESC, actor_rank
LIMIT 50;
