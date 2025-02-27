WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, 
           1 AS level, 
           m.production_year,
           t.kind AS movie_kind,
           COALESCE(tm.title, 'N/A') AS parent_title
    FROM aka_title m
    LEFT JOIN aka_title tm ON m.episode_of_id = tm.id
    JOIN kind_type t ON m.kind_id = t.id

    UNION ALL

    SELECT m.id AS movie_id, m.title, 
           mh.level + 1 AS level, 
           m.production_year,
           t.kind AS movie_kind,
           COALESCE(tm.title, 'N/A') AS parent_title
    FROM aka_title m
    INNER JOIN movie_hierarchy mh ON mh.movie_id = m.episode_of_id
    LEFT JOIN kind_type t ON m.kind_id = t.id
    LEFT JOIN aka_title tm ON mh.movie_id = tm.id
)
SELECT mh.movie_id, mh.title, mh.production_year, mh.movie_kind, mh.level, mh.parent_title,
       (SELECT COUNT(DISTINCT c.id)
        FROM cast_info c
        WHERE c.movie_id = mh.movie_id) AS total_cast,
       (SELECT STRING_AGG(DISTINCT a.name, ', ')
        FROM aka_name a
        INNER JOIN cast_info ci ON a.person_id = ci.person_id
        WHERE ci.movie_id = mh.movie_id) AS cast_names,
       (SELECT COUNT(DISTINCT k.keyword)
        FROM movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
        WHERE mk.movie_id = mh.movie_id) AS total_keywords
FROM movie_hierarchy mh
WHERE mh.production_year >= 2000
      AND (mh.movie_kind LIKE 'movie' OR mh.movie_kind = 'tv episode')
ORDER BY mh.production_year DESC, mh.level, mh.title;

