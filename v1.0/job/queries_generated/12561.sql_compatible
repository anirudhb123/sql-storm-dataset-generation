
SELECT 
    at.title AS movie_title,
    an.name AS actor_name,
    ct.kind AS company_type,
    tm.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_title at
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON at.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title tm ON at.id = tm.id
GROUP BY 
    at.title, an.name, ct.kind, tm.production_year
ORDER BY 
    tm.production_year DESC, movie_title;
