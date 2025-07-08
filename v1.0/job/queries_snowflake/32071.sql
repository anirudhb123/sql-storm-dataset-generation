
WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 
           1 AS level, ARRAY_CONSTRUCT(mt.id) AS path
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL

    UNION ALL

    SELECT et.id AS movie_id, et.title, et.production_year, 
           mh.level + 1, ARRAY_APPEND(mh.path, et.id)
    FROM aka_title et
    JOIN movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),

top_movies AS (
    SELECT mh.movie_id, mh.title, mh.production_year,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM movie_hierarchy mh
    JOIN complete_cast cc ON mh.movie_id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
), 
ranked_movies AS (
    SELECT tm.movie_id, tm.title, tm.production_year,
           tm.cast_count,
           RANK() OVER (ORDER BY tm.cast_count DESC) AS rank
    FROM top_movies tm
)

SELECT rm.rank, rm.title, rm.production_year, rm.cast_count,
       COALESCE(ak.name, 'Unknown') AS actor_name,
       CASE 
           WHEN rm.production_year >= 2000 THEN 'Modern'
           ELSE 'Classic'
       END AS era,
       LISTAGG(kw.keyword, ', ') AS keywords
FROM ranked_movies rm
LEFT JOIN cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN movie_keyword mw ON rm.movie_id = mw.movie_id
LEFT JOIN keyword kw ON mw.keyword_id = kw.id
WHERE rm.rank <= 10
GROUP BY rm.rank, rm.title, rm.production_year, rm.cast_count, ak.name
ORDER BY rm.rank;
