WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    COUNT(cast.id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
    AVG(pi.info IS NOT NULL AND pi.info <> '') AS avg_person_info,
    MAX(CASE WHEN LENGTH(ct.kind) < 10 THEN ct.kind ELSE NULL END) AS shortest_company_type,
    COUNT(DISTINCT km.keyword) FILTER (WHERE km.keyword IS NOT NULL) AS unique_keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info cast ON cc.subject_id = cast.person_id
LEFT JOIN 
    aka_name a ON cast.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword km ON mk.keyword_id = km.id
LEFT JOIN 
    person_info pi ON cast.person_id = pi.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, total_cast DESC;
