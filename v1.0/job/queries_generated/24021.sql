WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year,
           NULL AS parent_movie_id,
           0 AS level
    FROM aka_title mt
    WHERE mt.production_year > 2010
    
    UNION ALL
    
    SELECT ml.linked_movie_id AS movie_id,
           at.title, 
           at.production_year,
           mh.movie_id,
           mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_ranks AS (
    SELECT ci.movie_id, 
           ak.name, 
           RANK() OVER (PARTITION BY ci.movie_id ORDER BY cct.kind) AS role_rank,
           COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_cast
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN comp_cast_type cct ON ci.person_role_id = cct.id
),
keywords AS (
    SELECT mk.movie_id, 
           STRING_AGG(kw.keyword, ', ') AS all_keywords
    FROM movie_keyword mk
    JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY mk.movie_id
),
null_check AS (
    SELECT mt.id AS movie_id, 
           CASE 
               WHEN ki.info IS NOT NULL THEN ki.info 
               ELSE 'No Info Available' 
           END AS info
    FROM aka_title mt
    LEFT JOIN movie_info ki ON mt.id = ki.movie_id AND ki.note NOT LIKE '%deleted%'
),
final_results AS (
   SELECT mh.title,
          mh.production_year,
          cr.name AS cast_member,
          cr.role_rank,
          cr.total_cast, 
          COALESCE(kd.all_keywords, 'No Keywords') AS keywords,
          COALESCE(nc.info, 'Info Not Found') AS info_status
   FROM movie_hierarchy mh
   LEFT JOIN cast_ranks cr ON mh.movie_id = cr.movie_id
   LEFT JOIN keywords kd ON mh.movie_id = kd.movie_id
   LEFT JOIN null_check nc ON mh.movie_id = nc.movie_id
)
SELECT DISTINCT 
       fr.title,
       fr.production_year,
       fr.cast_member,
       fr.role_rank,
       fr.total_cast,
       fr.keywords,
       fr.info_status
FROM final_results fr
WHERE (fr.role_rank <= 3 OR fr.total_cast > 5)
AND fr.production_year IS NOT NULL
ORDER BY fr.production_year DESC, fr.title ASC;
