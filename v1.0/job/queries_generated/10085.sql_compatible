
SELECT 
    t.title, 
    ak.name AS aka_name, 
    c.nr_order, 
    c.note AS role_note, 
    ct.kind AS company_type, 
    p.info AS person_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, ak.name, c.nr_order, c.note, ct.kind, p.info
ORDER BY 
    t.title, c.nr_order;
