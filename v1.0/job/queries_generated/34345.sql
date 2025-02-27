WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, 0 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT ml.linked_movie_id, lt.title, mh.level + 1
    FROM movie_link ml
    JOIN title lt ON ml.linked_movie_id = lt.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorCount AS (
    SELECT ci.movie_id, COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
MoviesWithKeywords AS (
    SELECT mt.id AS movie_id, STRING_AGG(mk.keyword, ', ') AS keywords
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    WHERE mt.production_year >= 2000
    GROUP BY mt.id
)
SELECT mh.title AS Movie_Title,
       mh.level,
       COALESCE(ac.actor_count, 0) AS Actor_Count,
       COALESCE(mk.keywords, '(No Keywords)') AS Keywords,
       CASE 
           WHEN ac.actor_count IS NULL THEN 'Unproduced'
           WHEN ac.actor_count > 10 THEN 'Blockbuster'
           ELSE 'Indie'
       END AS Classification
FROM MovieHierarchy mh
LEFT JOIN ActorCount ac ON mh.movie_id = ac.movie_id
LEFT JOIN MoviesWithKeywords mk ON mh.movie_id = mk.movie_id
WHERE mh.level <= 1
ORDER BY mh.title;
