
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    k.keyword AS keyword,
    pi.info AS person_info
FROM 
    title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    person_info AS pi ON a.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND k.keyword LIKE '%action%'
GROUP BY 
    t.title, a.name, ct.kind, k.keyword, pi.info
ORDER BY 
    t.title, a.name;
