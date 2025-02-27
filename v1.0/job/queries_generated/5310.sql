SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    g.kind AS genre,
    c.name AS company_name,
    k.keyword AS keyword,
    pi.info AS actor_info,
    COUNT(mk.keyword_id) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type g ON t.kind_id = g.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
GROUP BY 
    a.name, t.title, g.kind, c.name, k.keyword, pi.info
HAVING 
    COUNT(mk.keyword_id) > 2
ORDER BY 
    COUNT(mk.keyword_id) DESC, a.name ASC;
