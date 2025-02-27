SELECT 
    a.name AS actor_name, 
    m.title AS movie_title, 
    c.nr_order AS cast_order, 
    cc.kind AS company_kind, 
    mt.info AS movie_info, 
    GROUP_CONCAT(k.keyword) AS keywords
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON m.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON m.id = cc.movie_id
WHERE 
    m.production_year >= 2000
AND 
    ct.kind = 'Distributor'
GROUP BY 
    a.name, m.title, c.nr_order, cc.kind, mt.info
ORDER BY 
    m.production_year DESC, c.nr_order ASC;
