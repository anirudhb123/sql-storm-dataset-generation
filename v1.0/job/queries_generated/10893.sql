SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    ct.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS number_of_companies,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
JOIN 
    title m ON m.id = at.movie_id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    a.name, m.title, m.production_year, ct.kind
ORDER BY 
    m.production_year DESC, actor_name;
