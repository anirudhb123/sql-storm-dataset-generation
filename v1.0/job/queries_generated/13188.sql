-- Performance Benchmarking SQL Query

SELECT 
    t.title AS Movie_Title,
    a.name AS Actor_Name,
    c.kind AS Role,
    m.production_year AS Production_Year,
    k.keyword AS Movie_Keyword
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    complete_cast cc ON at.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    company_name co ON mi.info_type_id = co.imdb_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    t.title;
