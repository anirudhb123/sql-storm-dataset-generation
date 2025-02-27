WITH RECURSIVE ActorHierarchy AS (
    SELECT c.id AS cast_id, c.person_id, c.movie_id, 1 AS level
    FROM cast_info c
    WHERE c.person_role_id IN (SELECT rt.id FROM role_type rt WHERE rt.role = 'Actor')

    UNION ALL

    SELECT c.id AS cast_id, c.person_id, c.movie_id, ah.level + 1
    FROM cast_info c
    JOIN ActorHierarchy ah ON c.movie_id = ah.movie_id
    WHERE c.person_id <> ah.person_id
),
TitleWithRoles AS (
    SELECT t.id AS title_id, t.title, 
           COUNT(DISTINCT c.person_id) AS actor_count,
           STRING_AGG(DISTINCT CONCAT(a.name, ' (', rt.role, ')'), ', ') AS actors_list
    FROM aka_title t
    LEFT JOIN cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN role_type rt ON c.role_id = rt.id
    GROUP BY t.id, t.title
),
TitleInfo AS (
    SELECT t.title, t.production_year, ti.info
    FROM TitleWithRoles t
    LEFT JOIN movie_info ti ON t.title_id = ti.movie_id
    WHERE ti.info_type_id IN (SELECT it.id FROM info_type it WHERE it.info = 'Box Office')
),
CombinedTitleInfo AS (
    SELECT COALESCE(ti.title, 'Unknown Title') AS title,
           COALESCE(ti.production_year, 1900) AS production_year,
           COALESCE(ti.info, 'N/A') AS info,
           c.actor_count,
           ti.actors_list
    FROM TitleWithRoles ti
    JOIN CombinedTitleInfo c ON ti.title_id = c.title_id
    WHERE ti.actor_count > 1
)
SELECT *, 
       ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank,
       COUNT(*) OVER () AS total_movies
FROM CombinedTitleInfo
WHERE lower(title) LIKE '%star%'
ORDER BY production_year DESC, actor_count DESC;
