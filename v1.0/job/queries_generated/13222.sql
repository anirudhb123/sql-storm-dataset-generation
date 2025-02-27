SELECT 
    t.title AS movie_title,
    a.name AS person_name,
    c.kind AS cast_role,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    company_name cn ON EXISTS (
        SELECT 1 
        FROM movie_companies mc 
        WHERE mc.movie_id = t.id AND mc.company_id = cn.id
    )
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year, a.name;
