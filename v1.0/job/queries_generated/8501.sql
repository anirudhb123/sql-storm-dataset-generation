SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_kind,
    ci.note AS cast_note,
    p.info AS person_info,
    mc.note AS company_note,
    k.keyword AS movie_keyword,
    tt.production_year
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    person_info p ON ci.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    kind_type tt ON t.kind_id = tt.id
WHERE 
    tt.kind = 'feature'
    AND ci.nr_order < 5
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'bio')
ORDER BY 
    tt.production_year DESC, 
    t.title ASC;
