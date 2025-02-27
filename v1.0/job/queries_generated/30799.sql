WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mcl.linked_movie_id,
        1 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link mcl ON mt.id = mcl.movie_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ml.linked_movie_id,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    ARRAY_AGG(DISTINCT cct.kind) AS company_kinds,
    AVG(r.role) AS average_role,
    SUM(CASE WHEN pi.info IS NULL THEN 1 ELSE 0 END) AS null_info_count
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    company_type cct ON mc.company_type_id = cct.id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id AND pi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'bio'
    )
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND ak.md5sum IS NOT NULL
GROUP BY 
    ak.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT kc.keyword) > 2
ORDER BY 
    at.production_year DESC, 
    keyword_count DESC;
