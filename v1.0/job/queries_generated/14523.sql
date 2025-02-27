SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
GROUP BY 
    a.name, t.title, c.kind, m.production_year
ORDER BY 
    m.production_year DESC, a.name;
