SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    m.info AS movie_info_detail
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id AND m.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Plot'
    )
WHERE 
    t.production_year > 2000
    AND co.country_code = 'USA'
    AND a.name IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name;
