WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, m.kind_id, 
           0 AS hierarchy_level, 
           CASE 
               WHEN m.production_year IS NULL THEN 'Unknown Year'
               ELSE CAST(m.production_year AS TEXT)
           END AS display_year
    FROM aka_title AS m
    WHERE m.production_year IS NOT NULL

    UNION ALL

    SELECT m.id AS movie_id, m.title, m.production_year, m.kind_id, 
           h.hierarchy_level + 1 AS hierarchy_level,
           h.display_year
    FROM MovieHierarchy AS h
    JOIN aka_title AS m ON h.movie_id = m.episode_of_id
    WHERE m.episode_of_id IS NOT NULL
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.role_id) AS total_roles,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes
FROM cast_info AS c
JOIN aka_name AS a ON c.person_id = a.person_id
JOIN aka_title AS t ON c.movie_id = t.id
LEFT JOIN movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN keyword AS k ON mk.keyword_id = k.id
LEFT JOIN MovieHierarchy AS h ON t.id = h.movie_id
LEFT JOIN person_info AS pi ON pi.person_id = c.person_id AND pi.info_type_id = 1  -- Assume info_type_id = 1 means Biography
WHERE t.production_year BETWEEN 2000 AND 2023
  AND (a.name ILIKE '%John%' OR a.name ILIKE '%Doe%')
  AND COALESCE(t.note, '') <> ''
GROUP BY a.name, t.title, t.production_year, h.hierarchy_level
HAVING COUNT(DISTINCT mk.keyword_id) > 0
ORDER BY t.production_year DESC, actor_name ASC, total_roles DESC;

WITH GenreCount AS (
    SELECT 
        k.keyword, 
        COUNT(DISTINCT mk.movie_id) AS movie_count
    FROM movie_keyword AS mk
    JOIN keyword AS k ON mk.keyword_id = k.id
    GROUP BY k.keyword
)
SELECT 
    g.keyword AS genre,
    g.movie_count,
    AVG(h.hierarchy_level) AS avg_hierarchy_level
FROM GenreCount AS g
JOIN MovieHierarchy AS h ON g.movie_count > 5
WHERE g.movie_count IS NOT NULL
GROUP BY g.keyword, g.movie_count
HAVING AVG(h.hierarchy_level) IS NOT NULL
ORDER BY g.movie_count DESC, avg_hierarchy_level ASC
LIMIT 10;
