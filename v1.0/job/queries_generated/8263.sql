SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year AS release_year,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies
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
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND kt.kind = 'movie'
    AND ci.nr_order < 5
GROUP BY 
    a.name, t.title, t.production_year, c.kind
ORDER BY 
    release_year DESC, actor_name;
