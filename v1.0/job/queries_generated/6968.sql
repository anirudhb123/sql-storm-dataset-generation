SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT k.keyword SEPARATOR ', ') AS keywords,
    GROUP_CONCAT(DISTINCT comp.name SEPARATOR ', ') AS companies,
    MIN(m.production_year) AS earliest_year,
    MAX(m.production_year) AS latest_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type kty ON t.kind_id = kty.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    it.info = 'Directed by'
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 0
ORDER BY 
    actor_name, movie_title;
