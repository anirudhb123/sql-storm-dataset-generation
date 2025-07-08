
WITH RECURSIVE ActorHierarchy AS (
    SELECT c.person_id, a.name, 1 AS depth
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.movie_id IN (SELECT id FROM aka_title WHERE production_year = 2023) 
      AND a.name IS NOT NULL
      
    UNION ALL

    SELECT c.person_id, a.name, ah.depth + 1
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN ActorHierarchy ah ON c.person_id = ah.person_id
    WHERE a.name IS NOT NULL
),
MovieDetails AS (
    SELECT t.id AS movie_id, t.title, t.production_year, COUNT(c.person_id) AS actor_count, 
           LISTAGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') WITHIN GROUP (ORDER BY a.name) AS actors
    FROM aka_title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN role_type r ON c.role_id = r.id
    WHERE t.production_year >= 2000 
    GROUP BY t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT m.movie_id, LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
),
FinalOutput AS (
    SELECT md.title, md.production_year, md.actor_count, mk.keywords,
           ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC) AS rank,
           COALESCE(mk.keywords, 'No Keywords') AS filtered_keywords
    FROM MovieDetails md
    LEFT JOIN MovieKeywords mk ON md.movie_id = mk.movie_id
)
SELECT f.title, f.production_year, f.actor_count, f.filtered_keywords
FROM FinalOutput f
WHERE f.actor_count > 5
  AND f.keywords IS NOT NULL
  AND f.rank <= 10
ORDER BY f.production_year DESC, f.actor_count DESC;
