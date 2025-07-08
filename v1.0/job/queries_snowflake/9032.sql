
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    LISTAGG(DISTINCT ckt.kind, ', ') WITHIN GROUP (ORDER BY ckt.kind) AS company_types,
    COUNT(DISTINCT ci.id) AS total_cast_members,
    COUNT(DISTINCT mci.company_id) AS total_companies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mci ON t.id = mci.movie_id
LEFT JOIN 
    company_type ckt ON mci.company_type_id = ckt.id
WHERE 
    t.production_year >= 2000 AND t.production_year <= 2023
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    t.production_year DESC, total_cast_members DESC
LIMIT 100;
