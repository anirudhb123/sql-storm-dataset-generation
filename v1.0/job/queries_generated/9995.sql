SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS character_name, 
    cy.name AS company_name, 
    m.production_year, 
    k.keyword AS movie_keyword, 
    GROUP_CONCAT(DISTINCT ci.note) AS cast_notes
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    char_name c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cy ON mc.company_id = cy.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000 AND 
    cy.country_code = 'USA'
GROUP BY 
    a.name, t.title, c.kind, cy.name, m.production_year, k.keyword
ORDER BY 
    t.production_year DESC, a.name;
