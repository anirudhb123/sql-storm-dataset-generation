
SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    kt.kind AS cast_type,
    c.name AS company_name,
    mi.info AS movie_info,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    COUNT(DISTINCT mc.company_id) AS total_companies
FROM 
    aka_title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON ci.movie_id = cc.movie_id
JOIN 
    aka_name AS ak ON ak.person_id = ci.person_id
JOIN 
    movie_companies AS mc ON mc.movie_id = cc.movie_id
JOIN 
    company_name AS c ON c.id = mc.company_id
JOIN 
    movie_info AS mi ON mi.movie_id = cc.movie_id
JOIN 
    movie_keyword AS mk ON mk.movie_id = cc.movie_id
JOIN 
    keyword AS k ON k.id = mk.keyword_id
JOIN 
    kind_type AS kt ON kt.id = t.kind_id
JOIN 
    role_type AS rt ON rt.id = ci.role_id
WHERE 
    t.production_year >= 2000
    AND k.keyword IN ('Action', 'Drama')
GROUP BY 
    t.title, ak.name, kt.kind, c.name, mi.info, k.keyword
ORDER BY 
    total_actors DESC, total_companies DESC
LIMIT 100;
