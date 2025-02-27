SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    COUNT(DISTINCT cc.person_id) AS cast_count,
    p.info AS actor_bio
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id AND p.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Biography'
    )
WHERE 
    t.production_year >= 2000
AND 
    t.kind_id IN (
        SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series')
    )
GROUP BY 
    a.name, t.title, t.production_year, p.info
ORDER BY 
    t.production_year DESC, a.name;
