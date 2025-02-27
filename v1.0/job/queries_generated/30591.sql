WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    COUNT(DISTINCT ci.person_id) OVER(PARTITION BY mh.movie_id) AS total_actors,
    SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY mh.movie_id) AS roles_assigned,
    STRING_AGG(DISTINCT ak.name, ', ') FILTER (WHERE ak.name IS NOT NULL) AS actor_names,
    COUNT(DISTINCT mi.info) FILTER (WHERE it.info = 'genres') AS genre_count,
    COALESCE(NULLIF(MAX(CASE WHEN cy.country_code = 'USA' THEN mc.note END), ''), 'Unknown') AS usa_company_note
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cy ON mc.company_id = cy.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    mh.level <= 3
GROUP BY 
    mh.movie_id, mh.movie_title
ORDER BY 
    total_actors DESC, mh.movie_title
LIMIT 50;
