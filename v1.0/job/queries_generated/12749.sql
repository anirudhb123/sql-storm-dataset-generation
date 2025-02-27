SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ct.kind AS character_type,
    c.name AS company_name,
    m.production_year,
    mk.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
ORDER BY 
    m.production_year DESC, t.title;
