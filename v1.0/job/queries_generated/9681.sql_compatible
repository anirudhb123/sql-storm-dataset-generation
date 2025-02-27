
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    COUNT(mk.keyword_id) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved,
    pi.info AS person_info,
    it.info AS extra_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    info_type it ON pi.info_type_id = it.id
WHERE 
    c.nr_order < 10 
    AND t.production_year > 2000 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    a.name, t.title, c.note, pi.info, it.info
ORDER BY 
    keyword_count DESC, a.name ASC;
