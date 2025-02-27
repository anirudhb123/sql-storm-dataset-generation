SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS cast_type,
    co.name AS company_name,
    MIN(m.production_year) AS earliest_release,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000
    AND co.country_code = 'USA'
    AND rt.role LIKE '%actor%'
GROUP BY 
    t.title, a.name, ct.kind, co.name
HAVING 
    COUNT(DISTINCT mi.info_type_id) > 1
ORDER BY 
    earliest_release DESC, movie_title;
