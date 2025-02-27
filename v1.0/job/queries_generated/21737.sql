WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year,
           NULL::integer AS parent_movie_id,
           1 AS depth
    FROM aka_title m
    WHERE m.production_year IS NOT NULL
      AND m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year,
           mh.movie_id AS parent_movie_id,
           mh.depth + 1
    FROM aka_title m
    JOIN movie_link ml ON ml.movie_id = mh.movie_id
    JOIN aka_title mm ON mm.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON mh.movie_id = mm.id
    WHERE mm.production_year IS NOT NULL
      AND mm.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    EXTRACT(YEAR FROM CURRENT_DATE) - mh.production_year AS age,
    COALESCE(CNT.actor_count, 0) AS actor_count,
    ARRAY_AGG(DISTINCT ak.name) AS actor_names,
    MAX(mc.company_name) AS main_company,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    NTILE(3) OVER (ORDER BY mh.production_year DESC) AS decade_tile
FROM movie_hierarchy mh
LEFT JOIN (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
) CNT ON CNT.movie_id = mh.movie_id
LEFT JOIN (
    SELECT mc.movie_id,
           cn.name AS company_name
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE cn.country_code = 'USA'
) mc ON mc.movie_id = mh.movie_id
LEFT JOIN movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN keyword kw ON kw.id = mk.keyword_id
LEFT JOIN aka_name ak ON ak.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = mh.movie_id)
WHERE mh.depth <= 3
AND mh.movie_id IS NOT NULL
GROUP BY mh.movie_id, mh.title, mh.production_year
ORDER BY age DESC, mh.title
LIMIT 50;
