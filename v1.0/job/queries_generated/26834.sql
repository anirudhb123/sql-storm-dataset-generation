SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    i.info AS director_info,
    k.keyword AS movie_keyword,
    ci.kind AS company_type,
    COUNT(DISTINCT c.note) AS distinct_roles
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON a.id = pi.person_id
JOIN 
    info_type i ON pi.info_type_id = i.id
JOIN 
    comp_cast_type ci ON c.person_role_id = ci.id
WHERE 
    t.production_year >= 2000
    AND cn.country_code = 'USA'
    AND (k.keyword ILIKE '%action%' OR k.keyword ILIKE '%drama%')
GROUP BY 
    t.title, a.name, i.info, k.keyword, ci.kind
ORDER BY 
    t.title, a.name;
