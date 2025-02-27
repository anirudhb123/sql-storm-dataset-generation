SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS character_role,
    m.name AS company_name,
    mk.keyword AS movie_keyword,
    SUM(mi.info) AS total_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON at.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
GROUP BY 
    t.title, a.name, c.kind, m.name, mk.keyword
ORDER BY 
    t.title;
