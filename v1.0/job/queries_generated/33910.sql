WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        t.title, 
        t.production_year, 
        ARRAY[t.title] AS title_path
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id 
    WHERE 
        c.country_code = 'USA' 
    AND 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id, 
        t.title, 
        t.production_year, 
        mh.title_path || t.title
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
)
SELECT 
    mh.movie_id,
    STRING_AGG(mh.title, ' -> ' ORDER BY mh.production_year) AS movie_chain,
    COUNT(DISTINCT c.person_id) AS cast_count,
    MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS director,
    AVG(CASE WHEN k.keyword IS NOT NULL THEN k.id END) AS average_keyword_id,
    COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS notable_cast_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_name an ON c.person_id = an.person_id
GROUP BY 
    mh.movie_id
ORDER BY 
    COUNT(DISTINCT c.person_id) DESC,
    mh.movie_id
LIMIT 10;
