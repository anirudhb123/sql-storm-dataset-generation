SELECT 
    ake.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT cct.kind) AS cast_types,
    GROUP_CONCAT(DISTINCT c.id) AS character_ids,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM
    aka_name ake
JOIN 
    cast_info ci ON ake.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    comp_cast_type cct ON ci.person_role_id = cct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    char_name cn ON ake.name = cn.name
WHERE 
    t.production_year BETWEEN 1990 AND 2020
GROUP BY 
    ake.name, t.id, t.title, t.production_year
HAVING 
    COUNT(DISTINCT cct.kind) > 1
ORDER BY 
    t.production_year DESC, actor_name ASC;
