SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.role_id AS cast_role,
    cn.name AS company_name,
    mt.kind AS company_type,
    tk.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword tk ON mk.keyword_id = tk.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, ak.name;
