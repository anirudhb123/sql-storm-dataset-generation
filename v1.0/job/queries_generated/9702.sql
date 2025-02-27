SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_kind,
    p.info AS person_info,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COALESCE(mo.year, 'N/A') AS movie_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    (SELECT 
         movie_id, 
         MAX(production_year) AS year 
     FROM 
         aka_title 
     GROUP BY 
         movie_id) mo ON t.id = mo.movie_id
WHERE 
    t.production_year >= 2000 AND 
    c.kind LIKE '%actor%'
GROUP BY 
    a.name, t.title, c.kind, p.info, mo.year
ORDER BY 
    t.title, a.name;
