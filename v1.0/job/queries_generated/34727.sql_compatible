
WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ca.person_id,
        a.name AS actor_name,
        1 AS level
    FROM cast_info ca
    JOIN aka_name a ON ca.person_id = a.person_id
    WHERE ca.nr_order = 1

    UNION ALL

    SELECT 
        ca.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM cast_info ca
    JOIN actor_hierarchy ah ON ca.movie_id IN (
        SELECT movie_id FROM cast_info WHERE person_id = ah.person_id
    )
    JOIN aka_name a ON ca.person_id = a.person_id
)

SELECT 
    at.title,
    at.production_year,
    COUNT(DISTINCT ca.person_id) AS total_cast,
    SUM(CASE WHEN ca.role_id = (SELECT id FROM role_type WHERE role = 'Lead') THEN 1 ELSE 0 END) AS lead_roles,
    COUNT(DISTINCT CASE WHEN ca.person_id IS NOT NULL THEN ca.person_id END) AS distinct_actors,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') THEN CAST(mi.info AS NUMERIC) ELSE NULL END) AS avg_box_office
FROM aka_title at
LEFT JOIN cast_info ca ON at.id = ca.movie_id
LEFT JOIN aka_name a ON ca.person_id = a.person_id
LEFT JOIN movie_info mi ON at.id = mi.movie_id
WHERE at.production_year >= 2000
GROUP BY at.title, at.production_year
HAVING COUNT(DISTINCT ca.person_id) > 5
ORDER BY total_cast DESC
LIMIT 10;
