WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, 1 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT m.id, m.title, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE mh.level < 3
),

cast_with_roles AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        c.movie_id,
        ct.kind AS role
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN comp_cast_type ct ON c.person_role_id = ct.id
    WHERE a.name IS NOT NULL
),

movie_keyword_info AS (
    SELECT 
        mk.movie_id,
        string_agg(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),

title_with_info AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        COALESCE(mki.keywords, 'No keywords') AS keywords,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM aka_title t
    LEFT JOIN movie_keyword_info mki ON t.id = mki.movie_id
    WHERE t.production_year IS NOT NULL
)

SELECT 
    th.title,
    th.production_year,
    mhi.level AS hierarchy_level,
    COUNT(DISTINCT cwr.actor_id) AS actor_count,
    th.keywords
FROM title_with_info th
LEFT JOIN movie_hierarchy mhi ON th.id = mhi.movie_id
LEFT JOIN cast_with_roles cwr ON th.id = cwr.movie_id
WHERE th.production_year BETWEEN 2000 AND 2023
GROUP BY th.title, th.production_year, mhi.level, th.keywords
ORDER BY th.production_year DESC, hierarchy_level ASC, actor_count DESC;
