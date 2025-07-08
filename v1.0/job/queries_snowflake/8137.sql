
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    LISTAGG(DISTINCT k.keyword, ',') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    ci.note AS cast_note,
    p.info AS person_info,
    ct.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ct.kind LIKE '%Production%'
GROUP BY 
    t.title, a.name, ci.note, p.info, ct.kind
ORDER BY 
    t.production_year DESC,
    a.name;
