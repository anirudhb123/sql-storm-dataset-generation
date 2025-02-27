
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT p.info, ', ') AS person_info
FROM
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE
    t.production_year BETWEEN 2000 AND 2023
    AND a.name LIKE '%John%'
GROUP BY
    a.name, t.title, t.production_year
ORDER BY
    t.production_year DESC, a.name;
