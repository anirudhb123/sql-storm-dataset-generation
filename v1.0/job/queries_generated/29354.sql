SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    k.keyword AS movie_keyword,
    ci.note AS role_note,
    c.kind AS company_type,
    GROUP_CONCAT(DISTINCT mci.note) AS company_notes
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_info_idx mii ON t.id = mii.movie_id
WHERE 
    ak.name IS NOT NULL AND 
    t.production_year BETWEEN 2000 AND 2020 AND 
    ci.nr_order <= 5
GROUP BY 
    ak.name, t.title, p.name, k.keyword, ci.note, c.kind
ORDER BY 
    t.production_year DESC, ak.name ASC;
