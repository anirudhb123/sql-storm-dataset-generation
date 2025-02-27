SELECT 
    t.title AS movie_title,
    an.name AS actor_name,
    ct.kind AS company_type,
    mt.info AS movie_info,
    kw.keyword AS movie_keyword
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name an ON cc.subject_id = an.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    keyword kw ON t.id = kw.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, an.name;
