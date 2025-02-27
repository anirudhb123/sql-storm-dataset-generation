SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    ci.note AS cast_note,
    COUNT(mk.keyword_id) AS keyword_count,
    MIN(m.production_year) AS earliest_year,
    MAX(m.production_year) AS latest_year
FROM 
    aka_title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_info AS mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget') 
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    t.title, a.name, ct.kind, ci.note 
ORDER BY 
    keyword_count DESC, earliest_year ASC;
