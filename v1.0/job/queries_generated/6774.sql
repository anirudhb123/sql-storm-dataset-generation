SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_kind,
    GROUP_CONCAT(k.keyword) AS keywords,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    info_type it ON m.info_type_id = it.id
WHERE 
    it.info = 'Box Office'
    AND t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.name, t.title, c.kind, m.info
ORDER BY 
    t.production_year DESC, actor_name;
