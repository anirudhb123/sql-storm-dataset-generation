WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title AS movie_title, mt.production_year, 0 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT mt.id AS movie_id, mt.title AS movie_title, mt.production_year, mh.level + 1
    FROM aka_title mt
    JOIN movie_link ml ON mt.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
actor_info AS (
    SELECT ka.name AS actor_name, cc.movie_id, cc.note AS role_note, rk.role AS role_name
    FROM cast_info cc
    JOIN aka_name ka ON cc.person_id = ka.person_id
    JOIN role_type rk ON cc.role_id = rk.id
),
keyword_summary AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
user_id_info AS (
    SELECT DISTINCT pi.person_id, pi.info AS user_notes, 
           ROW_NUMBER() OVER(PARTITION BY pi.person_id ORDER BY pi.id DESC) AS note_rank
    FROM person_info pi
    WHERE pi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%user%')
)
SELECT 
    mh.movie_title,
    mh.production_year,
    ai.actor_name,
    ai.role_name,
    ai.role_note,
    COALESCE(ks.keywords, 'No keywords') AS movie_keywords,
    CASE 
        WHEN u.user_notes IS NOT NULL THEN u.user_notes
        ELSE 'No user notes available' 
    END AS user_notes
FROM movie_hierarchy mh
LEFT JOIN actor_info ai ON mh.movie_id = ai.movie_id
LEFT JOIN keyword_summary ks ON mh.movie_id = ks.movie_id
LEFT JOIN user_id_info u ON ai.movie_id = u.person_id
WHERE mh.production_year BETWEEN 2000 AND 2020
  AND (ai.role_note IS NOT NULL OR ai.actor_name IS NOT NULL)
ORDER BY mh.production_year DESC, mh.movie_title, ai.actor_name;
