WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id,
           mt.title AS movie_title,
           1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    UNION ALL
    SELECT mt.id AS movie_id,
           CONCAT(mh.movie_title, ' (Sequel to: ', mt.title, ')') AS movie_title,
           mh.level + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN aka_title mt ON ml.movie_id = mt.id
    WHERE mh.level < 5
),
CastStats AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS actor_count,
           STRING_AGG(DISTINCT ak.name, ', ') AS actors,
           SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY ci.movie_id
)
SELECT mh.movie_id,
       mh.movie_title,
       COALESCE(cs.actor_count, 0) AS total_actors,
       COALESCE(cs.actors, 'No Cast') AS actor_names,
       COALESCE(cs.noted_roles, 0) AS roles_with_notes,
       mt.production_year,
       CASE 
           WHEN cs.actor_count > 10 THEN 'Star-Studded'
           WHEN cs.actor_count = 0 THEN 'No Actors'
           ELSE 'Moderate Cast'
       END AS cast_description
FROM MovieHierarchy mh
LEFT JOIN CastStats cs ON mh.movie_id = cs.movie_id
LEFT JOIN aka_title mt ON mh.movie_id = mt.id
WHERE mt.kind_id IN (1, 2, 3) -- Filters by specific movie kinds (e.g., Feature films)
  AND mt.production_year IS NOT NULL
  AND (mt.note IS NULL OR mt.note != 'N/A')
ORDER BY mh.level, mh.movie_title
LIMIT 50
OFFSET 10; -- Only fetch after the first 10 entries

