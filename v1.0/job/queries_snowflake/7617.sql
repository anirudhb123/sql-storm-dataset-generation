SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS cast_note,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS actor_movie_rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND co.country_code = 'USA'
    AND t.production_year >= 2000
ORDER BY 
    actor_name, movie_title;
