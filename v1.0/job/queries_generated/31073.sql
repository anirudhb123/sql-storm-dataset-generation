WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        NULL AS episode_of_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        m.episode_of_id,
        mh.level + 1
    FROM 
        aka_title m
        JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    ct.kind AS kind,
    COUNT(DISTINCT ci.person_id) AS num_actors,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    COUNT(DISTINCT mk.keyword) AS num_keywords,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = mh.movie_id 
            AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
        ) THEN 'Synopsis Available'
        ELSE 'No Synopsis'
    END AS synopsis_status
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    kind_type ct ON mh.kind_id = ct.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, ct.kind
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    mh.production_year DESC, num_actors DESC
LIMIT 10 OFFSET 5;
