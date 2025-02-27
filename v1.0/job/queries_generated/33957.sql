WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS hierarchy_level,
        NULL::integer AS parent_movie_id
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') AND mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        (SELECT title FROM aka_title WHERE id = ml.linked_movie_id) AS title,
        (SELECT production_year FROM aka_title WHERE id = ml.linked_movie_id) AS production_year,
        mh.hierarchy_level + 1,
        mh.movie_id AS parent_movie_id
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS total_actors,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE NULL END) AS average_order,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ARRAY_AGG(DISTINCT mp.company_name) AS production_companies,
    COUNT(DISTINCT CASE WHEN p.info IS NOT NULL THEN p.person_id END) AS persons_with_info
FROM movie_hierarchy mh
JOIN aka_title mt ON mh.movie_id = mt.id
LEFT JOIN complete_cast cc ON cc.movie_id = mt.id
LEFT JOIN cast_info c ON c.movie_id = cc.movie_id
LEFT JOIN aka_name ak ON ak.person_id = c.person_id
LEFT JOIN movie_keyword mk ON mk.movie_id = mt.id
LEFT JOIN keyword k ON k.id = mk.keyword_id
LEFT JOIN movie_companies mc ON mc.movie_id = mt.id
LEFT JOIN company_name mp ON mp.id = mc.company_id
LEFT JOIN person_info p ON p.person_id = ak.person_id
WHERE mh.hierarchy_level <= 2
GROUP BY ak.name, mt.title, mh.production_year
ORDER BY mh.production_year DESC, total_actors DESC;

This query assembles movie data starting from titles produced after 2000, including details about actors involved, production companies, keywords related to the titles, and distinct levels of a potential movie hierarchy based on linkage. Notably, it efficiently handles NULL logic, aggregates actor roles, and incorporates a recursive CTE for potential hierarchical movie relationships.
