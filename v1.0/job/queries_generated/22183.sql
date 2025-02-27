WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA' 
        AND m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
)

SELECT 
    h.movie_title,
    h.production_year,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count,
    nt.kind AS company_type
FROM 
    movie_hierarchy h
LEFT JOIN 
    cast_info ci ON h.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON h.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON h.movie_id = mc.movie_id
JOIN 
    company_type nt ON mc.company_type_id = nt.id
WHERE 
    h.depth = 1 
    AND h.production_year >= 2000 
    AND (k.phonetic_code IS NULL OR ak.name LIKE '%Smith%') 
GROUP BY 
    h.movie_id, h.movie_title, h.production_year, nt.kind
HAVING 
    COUNT(DISTINCT ak.name) > 0
ORDER BY 
    h.production_year DESC, h.movie_title ASC
LIMIT 100;
