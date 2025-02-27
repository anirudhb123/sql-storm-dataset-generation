WITH RECURSIVE MovieChain AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           0 AS depth
    FROM aka_title AS m
    WHERE m.title LIKE '%(1)%'
    
    UNION ALL
    
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           mc.depth + 1
    FROM aka_title AS m
    JOIN MovieChain AS mc ON m.episode_of_id = mc.movie_id
    WHERE mc.depth < 5
),
ActorRoles AS (
    SELECT a.id,
           a.person_id,
           a.movie_id,
           r.role,
           ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY r.role) AS role_rank
    FROM cast_info AS a
    JOIN role_type AS r ON a.role_id = r.id
    WHERE a.nr_order < 10
),
MovieKeywords AS (
    SELECT m.movie_id,
           STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword AS mk
    JOIN keyword AS k ON mk.keyword_id = k.id
    GROUP BY m.movie_id
),
CompleteCast AS (
    SELECT c.movie_id,
           COUNT(DISTINCT c.person_id) AS total_cast,
           STRING_AGG(DISTINCT r.role, ', ') AS roles,
           COALESCE(SUM(m.info_type_id = 1), 0) AS award_count
    FROM complete_cast AS c
    LEFT JOIN ActorRoles AS r ON c.movie_id = r.movie_id
    LEFT JOIN movie_info AS m ON c.movie_id = m.movie_id
    GROUP BY c.movie_id
)
SELECT mc.title,
       mc.production_year,
       COALESCE(cc.total_cast, 0) AS total_cast,
       COALESCE(mk.keywords, 'No Keywords') AS keywords,
       COALESCE(cc.award_count, 0) AS awards,
       CASE 
           WHEN cc.total_cast IS NULL THEN 'Unknown'
           WHEN cc.total_cast = 0 THEN 'No Cast'
           ELSE 'Total Cast Present'
       END AS cast_status
FROM MovieChain AS mc
LEFT JOIN CompleteCast AS cc ON mc.movie_id = cc.movie_id
LEFT JOIN MovieKeywords AS mk ON mc.movie_id = mk.movie_id
WHERE mc.title IS NOT NULL
  AND (mk.keywords IS NOT NULL OR cc.total_cast > 0)
ORDER BY mc.production_year DESC, mc.title;
