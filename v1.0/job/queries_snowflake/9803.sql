
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    y.production_year,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    title y ON t.id = y.id
WHERE 
    a.name IS NOT NULL 
    AND y.production_year BETWEEN 2000 AND 2020
    AND k.keyword IS NOT NULL
GROUP BY 
    a.name, t.title, y.production_year
ORDER BY 
    y.production_year DESC, a.name;
