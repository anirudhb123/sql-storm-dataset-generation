SELECT 
    t.title AS movie_title,
    GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
    GROUP_CONCAT(DISTINCT c.cast_name) AS cast_names,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    m.company_name AS production_company,
    p.info AS person_info
FROM 
    title t
JOIN 
    aka_title ak ON t.id = ak.movie_id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    name n ON c.person_id = n.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
LEFT JOIN 
    person_info p ON n.id = p.person_id
WHERE 
    t.production_year >= 2000 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'Feature Film')
GROUP BY 
    t.id, m.company_name, p.info
ORDER BY 
    t.production_year DESC, movie_title;
