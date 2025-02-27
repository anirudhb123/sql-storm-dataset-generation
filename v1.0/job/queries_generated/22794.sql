WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title, 1 AS level
    FROM aka_title m
    WHERE m.production_year > 2000

    UNION ALL

    SELECT k.linked_movie_id, m.title, mh.level + 1
    FROM movie_link k
    JOIN MovieHierarchy mh ON k.movie_id = mh.movie_id
    JOIN aka_title m ON k.linked_movie_id = m.id
)

, MovieKeywords AS (
    SELECT mt.movie_id, 
           ARRAY_AGG(DISTINCT mk.keyword) AS keywords
    FROM movie_keyword mt
    JOIN keyword mk ON mt.keyword_id = mk.id
    GROUP BY mt.movie_id
)

SELECT 
    COALESCE(a.name, 'Unknown') AS actor_name,
    COALESCE(t.title, 'Untitled') AS movie_title,
    COALESCE(mk.keywords, ARRAY[]::text[]) AS associated_keywords,
    mh.level AS hierarchy_level,
    COUNT(DISTINCT c.id) AS cast_count,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count,
    STRING_AGG(DISTINCT ci.note, ', ') AS notes
FROM aka_name a
LEFT JOIN cast_info ci ON a.person_id = ci.person_id
LEFT JOIN aka_title t ON ci.movie_id = t.id
LEFT JOIN MovieHierarchy mh ON t.id = mh.movie_id
LEFT JOIN MovieKeywords mk ON t.id = mk.movie_id
LEFT JOIN complete_cast cc ON t.id = cc.movie_id
LEFT JOIN company_name cn ON ci.movie_id = cn.imdb_id
LEFT JOIN (SELECT DISTINCT movie_id, company_id FROM movie_companies) mc ON mc.movie_id = t.id
WHERE a.name IS NOT NULL
AND (ci.note IS NULL OR ci.note NOT IN ('Cameo', 'Uncredited'))
GROUP BY a.name, t.title, mk.keywords, mh.level
HAVING COUNT(DISTINCT c.id) > 2
ORDER BY hierarchy_level DESC, actor_name ASC;

