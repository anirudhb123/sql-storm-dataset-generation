WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           CAST(NULL AS VARCHAR(32)) AS parent_title
    FROM aka_title m
    WHERE m.production_year IS NOT NULL
    
    UNION ALL

    SELECT m.id AS movie_id,
           COALESCE(m.title, 'Unknown') AS title, 
           COALESCE(m.production_year, 1900) AS production_year,
           mh.title AS parent_title
    FROM movie_link ml
    JOIN aka_title m ON m.id = ml.linked_movie_id 
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT DISTINCT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    COALESCE(mt.production_year, 'Unknown Year') AS production_year,
    COUNT(DISTINCT ci.role_id) OVER (PARTITION BY ak.id ORDER BY mt.production_year) AS role_count,
    STRING_AGG(DISTINCT ci.note, ', ' ORDER BY ci.nr_order) AS notes,
    CASE 
        WHEN EXISTS (SELECT 1 
                     FROM movie_keyword mk 
                     WHERE mk.movie_id = mt.id 
                     AND mk.keyword_id IS NULL) 
        THEN 'Contains NULL Keyword'
        ELSE 'All Keywords Present' 
    END AS keyword_status
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN aka_title mt ON ci.movie_id = mt.id
LEFT JOIN complete_cast cc ON mt.id = cc.movie_id
LEFT JOIN movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN (SELECT DISTINCT movie_id 
            FROM movie_info 
            WHERE info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_movies ON mt.id = box_office_movies.movie_id
WHERE mt.production_year > 2000
  AND ak.name IS NOT NULL
  AND ak.name NOT LIKE '%Unknown%'
GROUP BY ak.name, mt.title, mt.production_year, ak.id
HAVING COUNT(DISTINCT ci.role_id) > 1
ORDER BY role_count DESC, mt.production_year DESC;
