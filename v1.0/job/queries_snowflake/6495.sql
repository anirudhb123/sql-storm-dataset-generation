SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    g.kind AS genre,
    c.name AS company_name,
    m.info AS movie_info,
    k.keyword AS keyword
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    kind_type g ON t.kind_id = g.id
WHERE 
    t.production_year >= 2000 
    AND g.kind IN ('Action', 'Drama', 'Comedy')
ORDER BY 
    t.production_year DESC, a.name ASC
LIMIT 100;
