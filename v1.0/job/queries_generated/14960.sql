SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS company_role,
    m.info AS movie_info,
    k.keyword
FROM 
    title t
JOIN 
    aka_title ak ON t.id = ak.movie_id
JOIN 
    cast_info ci ON ak.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
    AND ct.kind = 'Production Company'
ORDER BY 
    t.production_year DESC, a.name;
