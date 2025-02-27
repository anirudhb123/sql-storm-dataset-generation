SELECT 
    t.title AS Movie_Title,
    a.name AS Actor_Name,
    p.info AS Actor_Info,
    c.kind AS Company_Type,
    k.keyword AS Movie_Keyword,
    tb.production_year AS Production_Year
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    person_info AS p ON a.person_id = p.person_id
JOIN 
    kind_type AS tb ON t.kind_id = tb.id
WHERE 
    tb.kind = 'Feature Film' 
    AND t.production_year > 2000 
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Awards')
ORDER BY 
    t.production_year DESC, 
    a.name;
