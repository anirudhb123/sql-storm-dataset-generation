WITH RECURSIVE 
   movie_hierarchy AS (
       SELECT 
           mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           0 AS level
       FROM 
           aka_title mt
       WHERE 
           mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
       
       UNION ALL
       
       SELECT 
           ml.linked_movie_id AS movie_id, 
           at.title, 
           at.production_year, 
           mh.level + 1
       FROM 
           movie_link ml
       JOIN 
           aka_title at ON ml.linked_movie_id = at.id
       JOIN 
           movie_hierarchy mh ON mh.movie_id = ml.movie_id
   ),
   cast_summary AS (
       SELECT 
           ci.movie_id, 
           COUNT(ci.person_id) AS total_cast,
           STRING_AGG(DISTINCT an.name, ', ') AS cast_names
       FROM 
           cast_info ci
       JOIN 
           aka_name an ON ci.person_id = an.person_id
       GROUP BY 
           ci.movie_id
   )
SELECT 
   mh.title AS movie_title,
   mh.production_year,
   cs.total_cast,
   cs.cast_names,
   COALESCE(mi.info, 'No extra info') AS info_details
FROM 
   movie_hierarchy mh
LEFT JOIN 
   cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
   movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
WHERE 
   mh.level = 0
   AND mh.production_year >= 2000
ORDER BY 
   mh.production_year DESC, 
   cs.total_cast DESC NULLS LAST
LIMIT 50;
