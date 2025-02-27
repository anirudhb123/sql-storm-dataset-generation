SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    y.kind AS movie_kind,
    p.info AS person_info,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(m.movie_id) AS movie_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    kind_type y ON t.kind_id = y.id
WHERE 
    t.production_year >= 2000
    AND i.info LIKE '%Awards%'
    AND k.keyword IN ('Action', 'Drama')
GROUP BY 
    a.name, t.title, y.kind, p.info, c.kind, k.keyword
ORDER BY 
    movie_count DESC, a.name;
