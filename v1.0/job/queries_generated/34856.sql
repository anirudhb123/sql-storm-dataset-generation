WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        m2.id AS movie_id,
        m2.title,
        m2.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title m2 ON ml.linked_movie_id = m2.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    akn.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    SUM(CASE WHEN mv.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget') THEN mv.info::numeric ELSE 0 END) AS total_budget,
    RANK() OVER (PARTITION BY akn.person_id ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank_by_companies
FROM
    aka_name akn
JOIN
    cast_info ci ON akn.person_id = ci.person_id
JOIN
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    movie_info mv ON at.id = mv.movie_id
WHERE
    akn.name IS NOT NULL
    AND at.production_year BETWEEN 2000 AND 2023
    AND akn.name NOT LIKE '%Unknown%'
GROUP BY
    akn.person_id, akn.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY
    actor_name,
    movie_title;
