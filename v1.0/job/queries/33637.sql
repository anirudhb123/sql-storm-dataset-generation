WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        1 AS level
    FROM cast_info ca
    WHERE ca.role_id = (SELECT id FROM role_type WHERE role = 'Lead')

    UNION ALL

    SELECT 
        ca.person_id,
        ca.movie_id,
        ah.level + 1
    FROM cast_info ca
    INNER JOIN ActorHierarchy ah ON ca.movie_id = ah.movie_id
    WHERE ca.person_id <> ah.person_id
)
SELECT 
    ak.name AS actor_name,
    kt.kind AS kind_of_movie,
    title.title AS title_of_movie,
    MAX(mi.info) AS info_detail,
    COUNT(DISTINCT ah.movie_id) AS movie_count,
    SUM(CASE WHEN ak.name IS NULL THEN 1 ELSE 0 END) AS null_actor_names
FROM ActorHierarchy ah
INNER JOIN aka_name ak ON ak.person_id = ah.person_id
INNER JOIN cast_info ci ON ci.person_id = ak.person_id
INNER JOIN title ON title.id = ci.movie_id
INNER JOIN kind_type kt ON kt.id = title.kind_id
LEFT JOIN movie_info mi ON mi.movie_id = title.id AND mi.info_type_id = 
        (SELECT id FROM info_type WHERE info = 'Box Office')
WHERE title.production_year >= 2000
GROUP BY ak.name, kt.kind, title.title
HAVING COUNT(DISTINCT ah.movie_id) > 1
ORDER BY movie_count DESC, actor_name ASC;
