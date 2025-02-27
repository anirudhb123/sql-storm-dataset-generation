WITH recursive movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.production_year > 2000
    UNION ALL
    SELECT m.id AS movie_id, m.title, m.production_year, h.level + 1
    FROM movie_hierarchy h
    JOIN movie_link ml ON ml.movie_id = h.movie_id
    JOIN aka_title m ON m.id = ml.linked_movie_id
    WHERE h.level < 5
),
cast_summary AS (
    SELECT ci.movie_id, COUNT(DISTINCT ci.person_id) AS total_cast, STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM cast_info ci
    JOIN aka_name ak ON ak.person_id = ci.person_id
    GROUP BY ci.movie_id
),
top_movies AS (
    SELECT mh.movie_id, mh.title, mh.production_year, cs.total_cast, cs.actors,
           ROW_NUMBER() OVER (ORDER BY mh.production_year DESC, cs.total_cast DESC) AS rn
    FROM movie_hierarchy mh
    LEFT JOIN cast_summary cs ON cs.movie_id = mh.movie_id
)
SELECT tm.title, tm.production_year, tm.total_cast,
       CASE WHEN tm.total_cast IS NULL THEN 'No Cast' ELSE tm.actors END AS cast_list,
       k.keyword, ct.kind
FROM top_movies tm
LEFT JOIN movie_keyword mk ON mk.movie_id = tm.movie_id
LEFT JOIN keyword k ON k.id = mk.keyword_id
LEFT JOIN movie_companies mc ON mc.movie_id = tm.movie_id
LEFT JOIN company_name cn ON cn.id = mc.company_id
LEFT JOIN company_type ct ON ct.id = mc.company_type_id
WHERE tm.rn <= 10
ORDER BY tm.production_year DESC, tm.total_cast DESC;
