SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    p.info AS actor_info,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT co.name) AS companies
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
    AND c.nr_order IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, p.info, c.kind
ORDER BY 
    t.production_year DESC, a.name;
