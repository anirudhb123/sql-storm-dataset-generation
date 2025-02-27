SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    cn.name AS company_name,
    k.keyword AS movie_keyword,
    m.info AS movie_info,
    p.info AS person_info,
    rl.role AS role_type
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    aka_title AS t ON c.movie_id = t.movie_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_info AS m ON t.id = m.movie_id
JOIN 
    person_info AS p ON a.person_id = p.person_id
JOIN 
    role_type AS rl ON c.role_id = rl.id
ORDER BY 
    a.name, t.title;
