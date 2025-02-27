SELECT 
    t.title AS movie_title,
    t.production_year,
    nam.name AS actor_name,
    GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies,
    rt.role AS actor_role,
    COUNT(DISTINCT ci.person_id) AS num_actors
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name nam ON ci.person_id = nam.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    nam.name IS NOT NULL
AND 
    t.kind_id IN (
        SELECT id FROM kind_type WHERE kind IN ('movie', 'short')
    )
GROUP BY 
    t.id, nam.name, t.production_year, rt.role
ORDER BY 
    t.production_year DESC, movie_title ASC;
