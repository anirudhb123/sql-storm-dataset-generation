
SELECT 
    t.title AS movie_title,
    COUNT(DISTINCT c.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies,
    AVG(CASE WHEN mi.info_type_id IS NOT NULL THEN LENGTH(mi.info) ELSE NULL END) AS avg_info_length
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, t.id
ORDER BY 
    cast_count DESC, t.title;
