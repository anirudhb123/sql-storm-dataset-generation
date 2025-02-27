SELECT 
    t.title AS movie_title,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MAX(sub.title) AS linked_movie_title,
    COUNT(DISTINCT pi.info) AS total_person_info,
    STRING_AGG(DISTINCT COALESCE(cn.name, 'Unknown Company'), ', ') AS production_companies,
    STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_link ml ON t.id = ml.movie_id
LEFT JOIN 
    title sub ON ml.linked_movie_id = sub.id
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND k.keyword ILIKE '%action%'
GROUP BY 
    t.title
ORDER BY 
    total_cast DESC, movie_title;