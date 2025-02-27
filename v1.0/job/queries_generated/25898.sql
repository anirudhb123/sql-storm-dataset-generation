SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    ct.kind AS cast_type,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    MAX(mi.info) AS additional_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    name p ON ak.person_id = p.imdb_id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ak.name, t.title, p.name, ct.kind
ORDER BY 
    t.production_year DESC, aka_name;
