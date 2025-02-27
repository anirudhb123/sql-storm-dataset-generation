WITH RECURSIVE CTE_MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 0 AS level
    FROM aka_title mt
    WHERE mt.kind_id = 1  -- Selecting only movies

    UNION ALL

    SELECT m.linked_movie_id, lt.title, lt.production_year, ch.level + 1
    FROM movie_link m
    JOIN aka_title lt ON m.linked_movie_id = lt.id
    JOIN CTE_MovieHierarchy ch ON m.movie_id = ch.movie_id
),

CTE_ActorRoles AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) OVER (PARTITION BY c.person_id) AS role_count
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
),

CTE_MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    a.actor_name,
    a.role_name,
    k.keywords,
    a.role_count,
    COALESCE(a.role_count, 0) AS total_roles,
    CASE 
        WHEN a.role_count > 5 THEN 'Multiple roles' 
        ELSE 'Single role' 
    END AS role_category
FROM CTE_MovieHierarchy h
LEFT JOIN CTE_ActorRoles a ON h.movie_id = a.movie_id
LEFT JOIN CTE_MovieKeywords k ON h.movie_id = k.movie_id
WHERE h.production_year >= 2000
ORDER BY h.production_year DESC, h.title, a.actor_name;
