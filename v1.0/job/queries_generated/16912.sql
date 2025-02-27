SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    cc.kind AS company_type,
    COUNT(*) AS num_actors
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title t ON ci.movie_id = t.movie_id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_type cc ON mc.company_type_id = cc.id
GROUP BY
    a.name, t.title, t.production_year, cc.kind
ORDER BY
    num_actors DESC
LIMIT 10;
