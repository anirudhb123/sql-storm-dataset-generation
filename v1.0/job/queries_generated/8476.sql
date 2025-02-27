SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS company_type,
    i.info AS movie_info,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT ca.id) AS cast_count
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ca ON cc.subject_id = ca.id
JOIN 
    aka_name ak ON ca.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ak.name LIKE '%Smith%'
GROUP BY 
    t.id, ak.name, c.kind, i.info
ORDER BY 
    t.production_year DESC, ak.name;
