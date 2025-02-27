SELECT 
    m.id AS movie_id,
    m.title AS movie_title,
    c.name AS company_name,
    k.keyword AS movie_keyword,
    a.name AS actor_name,
    r.role AS actor_role,
    pi.info AS person_info,
    ti.kind AS movie_kind,
    m.production_year,
    COUNT(DISTINCT ai.id) AS actor_count
FROM 
    aka_title AS m
JOIN 
    movie_companies AS mc ON m.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    movie_keyword AS mk ON m.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    cast_info AS ci ON m.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    role_type AS r ON ci.role_id = r.id
JOIN 
    person_info AS pi ON ci.person_id = pi.person_id
JOIN 
    kind_type AS ti ON m.kind_id = ti.id
WHERE 
    m.production_year >= 2000
    AND k.keyword ILIKE '%action%'
    AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    m.id, m.title, c.name, k.keyword, a.name, r.role, pi.info, ti.kind, m.production_year
ORDER BY 
    actor_count DESC, m.production_year DESC
LIMIT 50;
