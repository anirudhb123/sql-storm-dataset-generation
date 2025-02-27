WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        CONCAT('Sequel: ', m.title),
        level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.id
)
SELECT 
    mh.title,
    mh.level,
    ak.name AS actor_name,
    COUNT(ki.keyword) AS keyword_count,
    AVG(mi.info_length) AS avg_info_length,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_companies mc ON mh.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON mh.id = mi.movie_id
GROUP BY 
    mh.title, mh.level, ak.name
HAVING 
    COUNT(ki.keyword) > 1 AND 
    mh.level < 3
ORDER BY 
    mh.level, avg_info_length DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
