WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id, mt.title, mt.production_year, mt.kind_id, 
           COALESCE(b.title, 'N/A') AS base_title, 
           COALESCE(b.production_year, 0) AS base_year
    FROM aka_title mt
    LEFT JOIN movie_link ml ON mt.id = ml.movie_id
    LEFT JOIN aka_title b ON ml.linked_movie_id = b.id
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
      
    UNION ALL
    
    SELECT mt.id, mt.title, mt.production_year, mt.kind_id, 
           COALESCE(b.title, 'N/A'), 
           COALESCE(b.production_year, 0)
    FROM aka_title mt
    INNER JOIN movie_link ml ON mt.id = ml.movie_id
    INNER JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.id
)
SELECT 
    ka.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(mi.info ~* 'rating'::text::varchar) AS ratings_count,
    CFraction * 100 AS actor_contribution_percentage
FROM aka_name ka
INNER JOIN cast_info ci ON ka.person_id = ci.person_id
INNER JOIN movie_hierarchy mh ON ci.movie_id = mh.id
INNER JOIN aka_title at ON mh.id = at.id
LEFT JOIN movie_companies mc ON at.id = mc.movie_id
LEFT JOIN movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
LEFT JOIN movie_info mi ON at.id = mi.movie_id
CROSS JOIN (
    SELECT COUNT(*) AS CFraction
    FROM cast_info
) AS cf
WHERE at.production_year BETWEEN 2000 AND 2020
AND (mi.info IS NULL OR mi.info <> 'disqualified')
GROUP BY ka.name, at.title, at.production_year
HAVING COUNT(DISTINCT mc.company_id) > 1
ORDER BY actor_contribution_percentage DESC, at.production_year DESC;
