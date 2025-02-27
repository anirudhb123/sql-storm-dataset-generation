SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    y.year AS production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN title t ON c.movie_id = t.id
JOIN movie_info mi ON t.id = mi.movie_id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
JOIN (SELECT DISTINCT production_year FROM aka_title WHERE title IS NOT NULL) AS y ON t.production_year = y.year
WHERE a.name IS NOT NULL
GROUP BY a.name, t.title, c.note, y.year
ORDER BY y.year DESC, a.name;
