WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        linked_movie.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link linked_movie
    JOIN
        aka_title mt ON linked_movie.movie_id = mt.id
    JOIN
        movie_hierarchy mh ON linked_movie.movie_id = mh.movie_id
    WHERE
        mh.level < 3
)
SELECT
    ak.name AS actor_name,
    title.title AS movie_title,
    title.production_year,
    COUNT(DISTINCT ci.id) AS role_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.id) AS company_count,
    AVG(CASE 
            WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Birthday') 
            THEN CAST(pi.info AS DATE) 
            END) AS average_birthday_age,
    MAX(CASE 
            WHEN ci.person_role_id IS NULL 
            THEN 'Unknown Role' 
            ELSE rt.role 
        END) AS max_role
FROM
    aka_name ak
INNER JOIN
    cast_info ci ON ak.person_id = ci.person_id
INNER JOIN
    title ON ci.movie_id = title.id
LEFT JOIN
    movie_keyword mk ON title.id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN
    movie_companies mc ON title.id = mc.movie_id
LEFT JOIN
    company_name co ON mc.company_id = co.id
LEFT JOIN
    person_info pi ON ak.person_id = pi.person_id
LEFT JOIN
    role_type rt ON ci.role_id = rt.id
INNER JOIN
    movie_hierarchy mh ON title.id = mh.movie_id
WHERE
    title.production_year BETWEEN 2000 AND 2020
    AND ak.name IS NOT NULL
    AND (co.country_code IS NULL OR co.country_code <> 'USA')
GROUP BY
    ak.name, title.title, title.production_year
HAVING
    COUNT(DISTINCT ci.id) > 0
ORDER BY
    level, actor_name, movie_title;
