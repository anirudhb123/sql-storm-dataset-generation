WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        at.kind_id,
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
    mh.production_year,
    mh.level,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT c.name, ', ') AS company_names,
    COUNT(DISTINCT ki.keyword) AS keyword_count,
    AVG(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END) * 100 AS info_completion_rate,    
    SUM(CASE 
            WHEN rt.role = 'actor' THEN 1 
            ELSE 0 
        END) AS actor_count
FROM
    movie_hierarchy mh
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    company_name c ON mc.company_id = c.id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN
    role_type rt ON ci.role_id = rt.id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN
    info_type it ON mi.info_type_id = it.id
LEFT JOIN
    person_info pi ON ci.person_id = pi.person_id
WHERE
    mh.production_year > 2000
GROUP BY
    mh.movie_id, mh.movie_title, mh.production_year, mh.level
HAVING
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY
    mh.level DESC, 
    company_count DESC;

