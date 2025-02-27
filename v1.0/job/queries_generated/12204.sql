SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.nr_order AS cast_order,
    tt.kind AS title_kind,
    ci.note AS role_note
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    kind_type tt ON t.kind_id = tt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.title, ci.nr_order;
