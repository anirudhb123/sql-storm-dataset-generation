SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    tc.kind AS company_type,
    k.keyword AS movie_keyword,
    pc.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    keyword k ON t.id = (SELECT movie_id FROM movie_keyword WHERE keyword_id = k.id LIMIT 1)
JOIN 
    person_info pc ON a.person_id = pc.person_id
WHERE 
    t.production_year > 2000 
    AND k.keyword IN ('Action', 'Drama')
    AND ct.kind = 'Producer'
ORDER BY 
    t.production_year DESC, a.name;
