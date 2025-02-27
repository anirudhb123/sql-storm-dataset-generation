SELECT 
    t.title AS movie_title,
    COUNT(DISTINCT a.person_id) AS total_actors,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year >= 2000
    AND ci.note IS NULL
GROUP BY 
    t.title, c.kind, k.keyword, i.info
ORDER BY 
    total_actors DESC, t.title;
