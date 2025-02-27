SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword ASC) AS keywords,
    c.kind AS company_type,
    pi.info AS actor_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info AS pi ON a.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
    AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    a.name, t.title, t.production_year, c.kind, pi.info
ORDER BY 
    t.production_year DESC, a.name;
