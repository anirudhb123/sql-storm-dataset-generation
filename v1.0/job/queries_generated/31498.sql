WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title AS mt
    JOIN movie_companies AS mc ON mt.id = mc.movie_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        mt.title,
        mh.level + 1
    FROM 
        MovieHierarchy AS mh
    JOIN movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN aka_title AS mt ON ml.linked_movie_id = mt.id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    COUNT(DISTINCT c.person_id) AS total_actors,
    AVG(m.production_year) AS average_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) FILTER (WHERE mc.company_type_id = 2) AS production_companies,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name) AS actor_rank,
    COUNT(DISTINCT CASE WHEN p.info_type_id = 1 THEN p.info END) AS awards_count
FROM 
    aka_name AS a
JOIN cast_info AS c ON a.person_id = c.person_id
JOIN aka_title AS m ON c.movie_id = m.id
JOIN movie_keyword AS mk ON m.id = mk.movie_id
JOIN keyword AS k ON mk.keyword_id = k.id
JOIN movie_companies AS mc ON m.id = mc.movie_id
LEFT JOIN person_info AS p ON a.person_id = p.person_id
LEFT JOIN MovieHierarchy AS mh ON m.id = mh.movie_id
WHERE 
    c.nr_order IS NOT NULL 
    AND k.keyword IS NOT NULL
    AND m.production_year > 1990
GROUP BY 
    a.name, m.title
HAVING 
    COUNT(DISTINCT c.person_id) >= 5
ORDER BY 
    average_year DESC, actor_name ASC;
