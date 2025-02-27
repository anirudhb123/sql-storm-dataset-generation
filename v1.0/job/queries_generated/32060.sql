WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        mm.id AS movie_id, 
        mm.title AS movie_title, 
        mm.production_year,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title mm
    JOIN 
        movie_link ml ON ml.linked_movie_id = mm.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    mh.movie_title,
    mh.production_year,
    ak.name AS actor_name,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    COUNT(DISTINCT mk.keyword) AS num_keywords,
    STRING_AGG(DISTINCT ik.info, ', ') AS info_list,
    AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mh.movie_id) AS avg_roles
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id AND ci.nr_order < 3 -- Top 2 actors
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
LEFT JOIN 
    info_type it ON it.id = mi.info_type_id
LEFT JOIN 
    movie_info_idx ik ON ik.movie_id = mh.movie_id AND ik.info_type_id = it.id
WHERE 
    mh.parent_movie_id IS NULL -- Root movies only
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, ak.name
HAVING 
    COUNT(DISTINCT mk.keyword) > 5 -- Movies with more than 5 keywords
ORDER BY 
    mh.production_year DESC, 
    num_companies DESC;
