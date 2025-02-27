SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    cmt.kind AS company_type,
    it.info AS additional_info
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type cmt ON mc.company_type_id = cmt.id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    t.production_year >= 2000
    AND (it.info IS NOT NULL OR p.info IS NOT NULL)
GROUP BY 
    ak.name, t.title, c.nr_order, p.info, cmt.kind, it.info
ORDER BY 
    t.production_year DESC, ak.name;
