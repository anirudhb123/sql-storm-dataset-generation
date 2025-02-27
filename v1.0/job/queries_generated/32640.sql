WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000  -- Starting point: Movies from the year 2000 and onward

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM
        movie_hierarchy mh
    JOIN
        aka_title m ON mh.movie_id = m.episode_of_id
)

SELECT
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    ct.kind AS character_type,
    COALESCE(GROUP_CONCAT(DISTINCT kw.keyword), 'No Keywords') AS keywords,
    COUNT(DISTINCT cc.person_id) AS number_of_actors,
    SUM(CASE WHEN mp.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS info_count
FROM
    cast_info cc
JOIN
    aka_name a ON cc.person_id = a.person_id
JOIN
    movie_hierarchy mt ON cc.movie_id = mt.movie_id
JOIN
    role_type rt ON cc.role_id = rt.id
LEFT JOIN
    company_name cn ON cn.id = (SELECT company_id FROM movie_companies mc WHERE mc.movie_id = cc.movie_id LIMIT 1)
LEFT JOIN
    movie_keyword mk ON mk.movie_id = cc.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN
    movie_info mp ON mp.movie_id = mt.movie_id AND mp.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
JOIN
    comp_cast_type ct ON ct.id = cc.person_role_id
WHERE
    mt.production_year BETWEEN 2000 AND 2023
    AND (a.name IS NOT NULL OR rt.role IS NOT NULL)
GROUP BY
    a.name, mt.title, mt.production_year, ct.kind
ORDER BY
    mt.production_year DESC, a.name
LIMIT 100;

This complex SQL query performs the following operations:

1. **CTE (Common Table Expression)**: A recursive CTE named `movie_hierarchy` is created to build a hierarchy of movies, focusing on titles released from the year 2000 onward.
  
2. **Joins**: Various tables are joined using INNER JOIN and LEFT JOIN to gather relevant information about actors, movies, roles, companies, and keywords associated with the movies.

3. **Filtering**: The `WHERE` clause applies criteria to limit results to movies produced between 2000 and 2023. It also handles null values by checking if actor names or roles are not null.

4. **Aggregation**: The query counts distinct actors associated with each movie and concatenates keywords associated with the films, returning 'No Keywords' if none are found.

5. **Ordering**: Results are ordered by production year in descending order and then by actor name, enhancing readability.

6. **Limit**: The final output is restricted to 100 records for performance benchmarking.
