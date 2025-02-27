SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.note AS role_note, 
    p.info AS person_info, 
    k.keyword AS movie_keyword, 
    co.name AS production_company, 
    yt.kind AS movie_kind 
FROM 
    cast_info c 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    role_type r ON c.role_id = r.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    person_info p ON a.person_id = p.person_id 
JOIN 
    kind_type yt ON t.kind_id = yt.id 
WHERE 
    a.name LIKE 'A%' 
    AND t.production_year > 2000 
    AND k.keyword IN ('Action', 'Drama') 
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
