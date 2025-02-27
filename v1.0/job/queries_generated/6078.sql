SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    tk.keyword AS movie_keyword,
    co.name AS company_name,
    ti.info AS movie_info,
    k.kind AS movie_kind
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword tk ON mk.keyword_id = tk.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    kind_type k ON t.kind_id = k.id
WHERE 
    a.name LIKE 'A%' 
    AND t.production_year BETWEEN 2000 AND 2022
ORDER BY 
    t.production_year DESC, a.name ASC;
