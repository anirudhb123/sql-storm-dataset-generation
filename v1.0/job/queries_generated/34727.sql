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
    AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') THEN mi.info::numeric ELSE NULL END) AS avg_box_office
FROM aka_title at
LEFT JOIN cast_info ca ON at.id = ca.movie_id
LEFT JOIN aka_name a ON ca.person_id = a.person_id
LEFT JOIN movie_info mi ON at.id = mi.movie_id
WHERE at.production_year >= 2000
GROUP BY at.id, at.title, at.production_year
HAVING COUNT(DISTINCT ca.person_id) > 5
ORDER BY total_cast DESC
LIMIT 10;

-- Additional computations for performance benchmarking
WITH movie_keywords AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
filtered_movies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword_count, 0) AS keyword_count
    FROM aka_title m
    LEFT JOIN movie_keywords mk ON m.id = mk.movie_id
    WHERE m.production_year >= 2000
)
SELECT 
    fm.title,
    fm.keyword_count,
    ROW_NUMBER() OVER (ORDER BY fm.keyword_count DESC) AS ranking
FROM filtered_movies fm
WHERE fm.keyword_count > 2
ORDER BY fm.keyword_count DESC;


This SQL query leverages recursive Common Table Expressions (CTEs) to navigate through the hierarchy of actors, calculating the total number of cast members, lead roles, and distinct actors for films released since 2000. It also gathers information about the average box office earnings, filtering on specific criteria. Additionally, it implements another CTE for movie keywords, providing a separate ranking on the count of keywords associated with each film, showcasing various SQL features and constructs for performance benchmarking.
