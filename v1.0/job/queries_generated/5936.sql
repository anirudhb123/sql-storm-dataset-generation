SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords, 
    COUNT(DISTINCT pc.person_id) AS total_cast, 
    COALESCE(COUNT(DISTINCT p.id), 0) AS total_people
FROM 
    aka_name AS a 
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id 
JOIN 
    title AS t ON ci.movie_id = t.id 
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id 
JOIN 
    keyword AS k ON mk.keyword_id = k.id 
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id 
LEFT JOIN 
    person_info AS p ON a.person_id = p.person_id 
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
GROUP BY 
    a.name, t.title, c.kind 
ORDER BY 
    total_cast DESC, actor_name ASC;
