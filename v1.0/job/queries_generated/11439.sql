SELECT 
    cn.name AS company_name, 
    tt.title AS title, 
    array_agg(aka.name) AS aka_names,
    array_agg(ca.name) AS cast_names
FROM 
    movie_companies mc
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    aka_title tt ON mc.movie_id = tt.movie_id
JOIN 
    complete_cast cc ON mc.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name aka ON ci.person_id = aka.person_id
JOIN 
    name n ON ci.person_id = n.id
GROUP BY 
    cn.name, tt.title
ORDER BY 
    cn.name, tt.title;
