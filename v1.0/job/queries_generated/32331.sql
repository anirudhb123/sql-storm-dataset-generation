WITH RECURSIVE cast_hierarchy AS (
    SELECT
        c.id AS cast_id,
        c.movie_id,
        p.name AS person_name,
        r.role AS person_role,
        1 AS level
    FROM
        cast_info c
    JOIN
        aka_name p ON c.person_id = p.person_id
    JOIN
        role_type r ON c.role_id = r.id
    WHERE
        p.name IS NOT NULL

    UNION ALL
    
    SELECT
        cc.id AS cast_id,
        cc.movie_id,
        pa.name AS person_name,
        rr.role AS person_role,
        ch.level + 1
    FROM
        cast_info cc
    JOIN
        cast_hierarchy ch ON cc.movie_id = ch.movie_id
    JOIN
        aka_name pa ON cc.person_id = pa.person_id
    JOIN
        role_type rr ON cc.role_id = rr.id
    WHERE
        ch.level < 3 -- limit depth of hierarchy to avoid excessive recursion
)

SELECT
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT ch.person_name) AS cast_names,
    COUNT(DISTINCT ch.cast_id) AS total_cast,
    AVG(CASE WHEN ch.level = 1 THEN 1 ELSE 0 END) AS primary_cast_ratio,
    COUNT(DISTINCT CASE WHEN k.keyword IS NOT NULL THEN k.keyword END) AS keyword_count
FROM
    title t
LEFT JOIN
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN
    cast_hierarchy ch ON cc.subject_id = ch.cast_id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    t.production_year >= 2000
    AND (t.kind_id IS NULL OR t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Action%'))
GROUP BY
    t.id, t.title, t.production_year
ORDER BY
    t.production_year DESC, total_cast DESC;
