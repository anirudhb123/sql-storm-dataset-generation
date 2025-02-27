WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title, 1 AS level
    FROM aka_title m
    WHERE m.production_year = 2023

    UNION ALL

    SELECT m.id AS movie_id, m.title, mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS role_order
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    WHERE a.name IS NOT NULL
),

MoviesWithKeywords AS (
    SELECT 
        t.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id, t.title
)

SELECT 
    mh.level,
    mh.title AS movie_title,
    aw.actor_name,
    aw.role,
    mw.keywords,
    COUNT(DISTINCT CASE WHEN aw.role_order = 1 THEN aw.actor_name END) AS leading_actors,
    COALESCE(mi.info, 'No info available') AS additional_info
FROM MovieHierarchy mh
LEFT JOIN ActorRoles aw ON mh.movie_id = aw.movie_id
LEFT JOIN MoviesWithKeywords mw ON mh.title = mw.title
LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
GROUP BY mh.level, mh.title, aw.actor_name, aw.role, mw.keywords, mi.info
ORDER BY mh.level, leading_actors DESC, movie_title;