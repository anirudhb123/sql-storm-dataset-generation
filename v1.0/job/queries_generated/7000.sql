SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS company_type,
    ti.info AS more_info,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
    AND ak.name IS NOT NULL
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating')
GROUP BY 
    t.title, ak.name, c.kind, ti.info
ORDER BY 
    t.title ASC, ak.name ASC;
