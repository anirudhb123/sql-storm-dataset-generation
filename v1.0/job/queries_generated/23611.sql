WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level,
        ARRAY[mt.title] AS full_path
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1,
        mh.full_path || at.title
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id 
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.kind_id,
    COUNT(c.id) AS cast_count,
    AVG(CASE WHEN p.gender = 'M' THEN 1 ELSE NULL END) AS male_percentage,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cmt.note, '; ') AS company_notes,
    array_to_string(mh.full_path, ' -> ') AS movie_path
FROM 
    movie_hierarchy AS m
LEFT JOIN 
    cast_info AS c ON m.movie_id = c.movie_id
LEFT JOIN 
    person_info AS p ON c.person_id = p.person_id
LEFT JOIN 
    movie_keyword AS mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies AS mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name AS cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info AS mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'note' LIMIT 1)
LEFT JOIN 
    movie_info_idx AS mii ON m.movie_id = mii.movie_id AND mii.info_type_id = mi.info_type_id
LEFT JOIN 
    complete_cast AS cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    aka_name AS an ON cc.subject_id = an.person_id
LEFT JOIN 
    aka_title AS at ON cc.movie_id = at.id
LEFT JOIN 
    movie_link AS ml ON m.movie_id = ml.movie_id
LEFT JOIN 
    movie_info AS cmt ON mc.movie_id = cmt.movie_id AND cmt.note IS NOT NULL
WHERE 
    m.production_year >= 2000
    AND m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv movie', 'mini-series'))
GROUP BY 
    m.movie_id, m.title, m.production_year, m.kind_id, mh.full_path
HAVING 
    COUNT(DISTINCT c.id) > 5
ORDER BY 
    m.production_year DESC,
    male_percentage DESC NULLS LAST
LIMIT 50;
