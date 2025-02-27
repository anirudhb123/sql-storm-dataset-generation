WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    pt.name,
    count(DISTINCT cc.movie_id) AS movie_count,
    MAX(mh.level) AS max_depth,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
    SUM(CASE WHEN pc.role_id IS NOT NULL THEN 1 ELSE 0 END) AS has_roles,
    COALESCE(SUM(CASE WHEN pm.info IS NOT NULL THEN 1 ELSE 0 END), 0) AS person_info_count,
    COUNT(DISTINCT CASE WHEN at.kind_id IN (1, 2) THEN at.id END) AS feature_length_count
FROM 
    aka_name pt
LEFT JOIN 
    cast_info ci ON pt.person_id = ci.person_id
LEFT JOIN 
    title at ON ci.movie_id = at.id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    person_info pm ON pt.person_id = pm.person_id AND pm.info_type_id = 1
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    complete_cast cc ON at.id = cc.movie_id
LEFT JOIN 
    role_type pc ON cc.subject_id = pc.id
WHERE 
    pt.name IS NOT NULL
    AND pt.name != ''
    AND (at.production_year IS NULL OR at.production_year >= 2000)
GROUP BY 
    pt.name
HAVING 
    movie_count > 5
ORDER BY 
    max_depth DESC, 
    movie_count DESC
LIMIT 100;
