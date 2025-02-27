SELECT
    t.title,
    a.name,
    c.note,
    m.production_year
FROM
    title t
JOIN
    aka_title a ON t.id = a.movie_id
JOIN
    cast_info c ON a.movie_id = c.movie_id
JOIN
    movie_info m ON a.movie_id = m.movie_id
WHERE
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
ORDER BY
    m.production_year DESC;
