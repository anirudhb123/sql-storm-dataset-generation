WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        0 AS level
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.level + 1
    FROM 
        movie_hierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(CASE 
        WHEN ci.note IS NOT NULL THEN 1 
        ELSE 0 
    END) AS average_note_presence,
    STRING_AGG(DISTINCT ak.name, ', ') FILTER (WHERE ak.name IS NOT NULL) AS known_aliases,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    MAX(mi.info) AS additional_info
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    complete_cast AS cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name AS ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword AS mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_info AS mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.level < 3 
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Director%')
GROUP BY 
    mh.movie_id,
    mh.movie_title
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    total_cast DESC
LIMIT 10;
