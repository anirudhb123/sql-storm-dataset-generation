SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(c.movie_id) AS total_movies,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT ci.kind ORDER BY ci.kind) AS company_types
FROM 
    aka_title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS c ON cc.subject_id = c.person_id
JOIN 
    aka_name AS a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
LEFT JOIN 
    company_name AS cn ON mc.company_id = cn.id
LEFT JOIN 
    info_type AS it ON mc.note = it.id
GROUP BY 
    t.id, a.id
HAVING 
    COUNT(c.movie_id) > 2
ORDER BY 
    total_movies DESC, movie_title;
