SELECT
    at.title,
    ak.name AS actor_name,
    ct.kind AS role_type
FROM
    aka_title AS at
JOIN
    cast_info AS ci ON at.id = ci.movie_id
JOIN
    aka_name AS ak ON ci.person_id = ak.person_id
JOIN
    role_type AS ct ON ci.role_id = ct.id
WHERE
    at.production_year >= 2000
ORDER BY
    at.production_year DESC;
