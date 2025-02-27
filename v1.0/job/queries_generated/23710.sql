WITH recursive movie_hierarchy AS (
    SELECT m.id AS movie_id, 
           t.title AS movie_title, 
           t.production_year,
           0 AS level
    FROM aka_title t
    JOIN movie_info mi ON t.id = mi.movie_id
    WHERE t.production_year IS NOT NULL

    UNION ALL

    SELECT mh.movie_id, 
           CONCAT(mh.movie_title, ' (Linked)') AS movie_title, 
           NULL AS production_year,
           mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, ranked_cast AS (
    SELECT ci.movie_id,
           ak.name AS actor_name,
           RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank,
           COUNT(ci.person_id) OVER (PARTITION BY ci.movie_id) AS total_cast
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
)
, movie_keywords AS (
    SELECT mk.movie_id, 
           STRING_AGG(k.keyword, ', ' ORDER BY k.keyword) AS all_keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    r.actor_name,
    r.actor_rank,
    r.total_cast,
    COALESCE(mk.all_keywords, 'No keywords') AS keywords,
    CASE 
        WHEN mh.level > 0 THEN 'Linked Movie' 
        ELSE 'Original Movie' 
    END AS movie_type
FROM movie_hierarchy mh
LEFT JOIN ranked_cast r ON mh.movie_id = r.movie_id
LEFT JOIN movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE (mh.production_year IS NOT NULL OR mh.level > 0)
AND (r.actor_rank <= 3 OR r.actor_rank IS NULL)
ORDER BY mh.production_year DESC, mh.movie_title, r.actor_rank;
