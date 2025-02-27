
WITH RankedTitles AS (
    SELECT
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn,
        a.id
    FROM
        aka_title a
    JOIN
        movie_keyword mk ON a.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
)
SELECT
    n.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    COUNT(DISTINCT c.person_role_id) AS distinct_role_count
FROM
    cast_info c
JOIN
    aka_name n ON c.person_id = n.person_id
JOIN
    RankedTitles t ON c.movie_id = t.id
JOIN
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
WHERE
    t.production_year >= 2000
AND
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
AND
    n.name IS NOT NULL
GROUP BY
    n.name, t.title, t.production_year
HAVING
    COUNT(DISTINCT kw.keyword) > 2
ORDER BY
    t.production_year DESC, actor_name;
