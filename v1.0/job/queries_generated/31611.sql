WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m 
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    WHERE 
        mh.level < 3
)

SELECT 
    mh.title AS "Related Movie Title",
    mh.production_year AS "Year",
    ak.name AS "Actor Name",
    COUNT(DISTINCT kc.keyword) AS "Keyword Count",
    MAX(pi.info) FILTER (WHERE it.info ILIKE '%Age%') AS "Age Info",
    COUNT(DISTINCT cc.role_id) AS "Role Count",
    SUM(CASE WHEN ac.kind ILIKE '%Producer%' THEN 1 ELSE 0 END) AS "Producer Count"
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type ac ON mc.company_type_id = ac.id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.title, mh.production_year, ak.name
ORDER BY 
    "Year" DESC, "Keyword Count" DESC;
