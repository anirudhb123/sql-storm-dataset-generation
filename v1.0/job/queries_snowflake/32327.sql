
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt 
    WHERE
        mt.production_year > 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.level < 3
)

SELECT
    h.movie_title,
    h.production_year,
    COUNT(DISTINCT c.id) AS actor_count,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    LISTAGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(mv.production_year) AS avg_production_year
FROM
    movie_hierarchy h
LEFT JOIN
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN
    cast_info c ON cc.subject_id = c.id
LEFT JOIN
    movie_companies mc ON h.movie_id = mc.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id
LEFT JOIN
    movie_keyword mk ON h.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    aka_title mv ON h.movie_id = mv.id
WHERE
    cn.country_code IS NOT NULL
GROUP BY
    h.movie_id, h.movie_title, h.production_year
HAVING
    COUNT(DISTINCT c.id) > 1 OR COUNT(DISTINCT mc.company_id) > 5
ORDER BY
    h.production_year DESC, actor_count DESC;
