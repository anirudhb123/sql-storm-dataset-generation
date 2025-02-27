WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM title mt
    WHERE mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    cm.name AS company_name,
    COUNT(ci.id) AS num_cast_members,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    AVG(CASE WHEN pi.info IS NOT NULL THEN pi.info ELSE 0 END) AS avg_info_score
FROM movie_hierarchy mh
LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN company_name cm ON mc.company_id = cm.id
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN aka_title ak ON ak.movie_id = mh.movie_id
LEFT JOIN person_info pi ON pi.person_id = ci.person_id AND pi.info_type_id = 1
WHERE mh.level <= 3
GROUP BY mh.movie_id, mh.title, mh.production_year, cm.name
ORDER BY mh.production_year DESC, mh.level ASC;
