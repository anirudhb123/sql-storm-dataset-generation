SELECT 
    t.title, 
    ak.name AS aka_name, 
    c.role_id, 
    cn.name AS company_name, 
    mk.keyword, 
    pi.info
FROM 
    title AS t
JOIN 
    aka_title AS ak_t ON t.id = ak_t.movie_id
JOIN 
    aka_name AS ak ON ak_t.id = ak.id
JOIN 
    cast_info AS c ON t.id = c.movie_id
JOIN 
    company_name AS cn ON c.movie_id = cn.imdb_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    person_info AS pi ON c.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    t.title;
