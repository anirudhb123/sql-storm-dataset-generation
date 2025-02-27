SELECT 
    at.title AS movie_title,
    an.name AS actor_name,
    at.production_year,
    c.kind AS role_kind,
    GROUP_CONCAT(kw.keyword) AS keywords
FROM 
    aka_title at
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    at.title, an.name, at.production_year, c.kind
ORDER BY 
    at.production_year DESC, movie_title;
