SELECT 
    t.title,
    p.name,
    c.note
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info pi ON cc.subject_id = pi.person_id
JOIN 
    name p ON pi.person_id = p.imdb_id
JOIN 
    cast_info c ON p.id = c.person_id AND c.movie_id = t.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title;
