WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        t.season_nr,
        1 AS level
    FROM title t
    WHERE t.episode_of_id IS NULL -- Starting point: top-level titles
    
    UNION ALL
    
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        t.season_nr,
        th.level + 1
    FROM title t
    JOIN title_hierarchy th ON t.episode_of_id = th.title_id -- Joining on episode_of_id to get child titles
),
person_roles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        r.role AS person_role,
        COUNT(ci.id) OVER (PARTITION BY ci.movie_id, r.role) AS role_count
    FROM cast_info ci
    JOIN role_type r ON r.id = ci.role_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        string_agg(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY mk.movie_id
),
movie_info_with_keywords AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        m.production_year,
        COALESCE(kw.keywords, 'No Keywords') AS keywords,
        COALESCE(pr.person_role, 'Unknown' ) AS main_role,
        pr.role_count
    FROM aka_title m
    LEFT JOIN movie_keywords kw ON kw.movie_id = m.id
    LEFT JOIN person_roles pr ON pr.movie_id = m.id
)
SELECT 
    th.title,
    th.production_year,
    mkw.keywords,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    COUNT(DISTINCT mk.movie_id) AS related_movies_count,
    AVG(mk.production_year) OVER (PARTITION BY a.person_id) AS avg_actor_movie_year,
    CASE 
        WHEN COUNT(DISTINCT mk.movie_id) > 5 THEN 'Prolific Actor'
        ELSE 'Less Active Actor'
    END AS actor_activity
FROM title_hierarchy th
LEFT JOIN movie_info_with_keywords mkw ON mkw.movie_id = th.title_id
LEFT JOIN aka_name a ON mkw.main_role = a.name
LEFT JOIN movie_link ml ON ml.movie_id = th.title_id
LEFT JOIN title linked_title ON linked_title.id = ml.linked_movie_id
LEFT JOIN movie_keyword mk ON mk.movie_id = linked_title.id
WHERE th.level <= 3 -- Limiting the results to avoid performance overhead
GROUP BY th.title, th.production_year, mkw.keywords, a.name, a.person_id
ORDER BY th.production_year DESC, actor_activity DESC;
