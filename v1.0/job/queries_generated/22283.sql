WITH recursive cast_hierarchy AS (
    SELECT
        ci.movie_id,
        ci.person_id,
        1 AS level
    FROM
        cast_info ci
    WHERE
        ci.nr_order = 1
    
    UNION ALL
    
    SELECT
        ci.movie_id,
        ci.person_id,
        ch.level + 1
    FROM
        cast_info ci
    JOIN
        cast_hierarchy ch ON ch.movie_id = ci.movie_id AND ch.person_id <> ci.person_id
    WHERE
        ci.nr_order = ch.level + 1
),
title_info AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind,
        mt.info AS theme
    FROM
        title t
    LEFT JOIN
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN
        movie_info mt ON mt.movie_id = t.id AND mt.info_type_id = (SELECT id FROM info_type WHERE info = 'Theme')
)
SELECT
    ak.name AS actor_name,
    ti.title AS movie_title,
    ti.production_year,
    h.level AS cast_level,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS production_companies,
    SUM(CASE WHEN NOT EXISTS (SELECT 1 FROM aka_title at WHERE at.movie_id = ti.title_id AND at.title LIKE '%Sequel%') THEN 1 ELSE 0 END) AS is_original
FROM
    cast_hierarchy h
JOIN
    aka_name ak ON ak.person_id = h.person_id
JOIN
    title_info ti ON ti.title_id = h.movie_id
LEFT JOIN
    movie_companies mc ON mc.movie_id = h.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id
GROUP BY
    ak.name, ti.title, ti.production_year, h.level
HAVING
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY
    ti.production_year DESC, h.level ASC;

