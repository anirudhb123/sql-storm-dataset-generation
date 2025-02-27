SELECT
    a.name AS aka_name,
    t.title AS movie_title,
    ci.note AS cast_note,
    p.info AS person_info
FROM
    aka_name AS a
JOIN
    cast_info AS ci ON a.person_id = ci.person_id
JOIN
    title AS t ON ci.movie_id = t.id
JOIN
    person_info AS p ON a.person_id = p.person_id
WHERE
    p.info_type_id = 1
ORDER BY
    t.production_year DESC;
