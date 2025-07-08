
WITH MovieHierarchy AS (
    
    SELECT ml.movie_id, ml.linked_movie_id, 1 AS level
    FROM movie_link ml
    WHERE ml.link_type_id = 1 
    
    UNION ALL
    
    SELECT ml.movie_id, ml.linked_movie_id, mh.level + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.linked_movie_id
    WHERE ml.link_type_id = 1
),
MovieKeywords AS (
    
    SELECT m.id AS movie_id, 
           LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords, 
           COUNT(k.id) AS keyword_count
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id
),
PersonMovieInfo AS (
    
    SELECT p.name AS actor_name,
           AT.title AS movie_title,
           COUNT(DISTINCT c.id) AS number_of_roles,
           AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS roles_with_notes_ratio
    FROM cast_info c
    JOIN aka_name p ON c.person_id = p.person_id
    JOIN aka_title AT ON c.movie_id = AT.movie_id
    GROUP BY p.name, AT.title
)
SELECT 
    mh.movie_id AS primary_movie_id,
    m.title AS primary_movie_title,
    mk.keywords AS associated_keywords,
    pm.actor_name AS starring_actor,
    pm.number_of_roles,
    pm.roles_with_notes_ratio,
    COALESCE(mh.level, 0) AS hierarchy_level
FROM MovieHierarchy mh
JOIN aka_title m ON mh.movie_id = m.id
LEFT JOIN MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN PersonMovieInfo pm ON pm.movie_title = m.title
WHERE 
    m.production_year >= 2000
    AND mk.keyword_count > 5
    AND (pm.number_of_roles > 0 OR pm.actor_name IS NULL)
ORDER BY primary_movie_id, primary_movie_title, hierarchy_level;
