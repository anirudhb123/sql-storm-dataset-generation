SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year AS release_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    cp.kind AS company_type,
    ci.note AS cast_note
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type cp ON mc.company_type_id = cp.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    ci.person_role_id IN (SELECT id FROM role_type WHERE role IN ('Actor', 'Supporting Actor'))
GROUP BY 
    a.name, t.title, t.production_year, cp.kind, ci.note
ORDER BY 
    t.production_year DESC, a.name;
