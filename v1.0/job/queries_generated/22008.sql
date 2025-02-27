WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    m.title,
    m.production_year,
    c.name AS company_name,
    p.name AS actor_name,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    SUM(CASE WHEN r.role = 'lead' THEN 1 ELSE 0 END) OVER (PARTITION BY m.id) AS lead_roles,
    COUNT(DISTINCT p2.id) AS total_actors,
    CASE 
        WHEN COUNT(DISTINCT p.id) > 10 THEN 'Many Actors'
        WHEN COUNT(DISTINCT p.id) BETWEEN 5 AND 10 THEN 'Moderate Actors'
        ELSE 'Few Actors' 
    END AS actor_density,
    mht.level AS movie_level,
    COALESCE(ci.note, 'No Comment') AS cast_comment
FROM MovieHierarchy mht
JOIN aka_title m ON mht.movie_id = m.id
LEFT JOIN movie_companies mc ON mc.movie_id = m.id
LEFT JOIN company_name c ON mc.company_id = c.id
LEFT JOIN cast_info ci ON ci.movie_id = m.id
LEFT JOIN aka_name p ON ci.person_id = p.person_id
LEFT JOIN movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN role_type r ON ci.role_id = r.id
WHERE m.production_year > 2010
  AND (c.country_code IS NULL OR c.country_code <> 'USA')
GROUP BY m.id, c.name, p.name, r.role, mht.level, ci.note
HAVING COUNT(DISTINCT k.id) >= 3
ORDER BY m.production_year DESC, actor_density, keyword_count DESC;
