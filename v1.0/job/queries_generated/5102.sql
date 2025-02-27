SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.gender AS person_gender,
    c.kind AS company_kind,
    GROUP_CONCAT(k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT ci.note) AS cast_notes
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    ak.name, t.title, p.gender, c.kind
ORDER BY 
    t.production_year DESC, ak.name;
