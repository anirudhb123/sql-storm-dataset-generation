SELECT
    t.title AS Movie_Title,
    a.name AS Actor_Name,
    r.role AS Role,
    c.note AS Cast_Note,
    co.name AS Company_Name,
    k.keyword AS Keyword,
    ti.info AS Movie_Info
FROM
    title t
JOIN
    cast_info c ON t.id = c.movie_id
JOIN
    aka_name a ON c.person_id = a.person_id
JOIN
    role_type r ON c.role_id = r.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name co ON mc.company_id = co.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    info_type ti ON mi.info_type_id = ti.id
WHERE
    t.production_year BETWEEN 1990 AND 2020
    AND co.country_code = 'USA'
    AND k.keyword LIKE '%Action%'
ORDER BY
    t.production_year DESC, a.name ASC;
