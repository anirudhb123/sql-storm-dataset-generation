WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, 
           COALESCE(p.name, 'Unknown') AS producer_name,
           0 AS level
    FROM aka_title m
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name p ON mc.company_id = p.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'producer')
    
    UNION ALL
    
    SELECT m.id, m.title, 
           COALESCE(p.name, 'Unknown') AS producer_name,
           mh.level + 1
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name p ON mc.company_id = p.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'producer')
)

SELECT mh.title AS Movie_Title,
       mh.producer_name AS Producer,
       CASE 
           WHEN mh.level = 0 THEN 'Original Movie'
           WHEN mh.level > 0 THEN 'Linked Movie Level ' || mh.level
           ELSE 'Unknown Level'
       END AS Movie_Status,
       COUNT(CASE WHEN c.movie_id IS NOT NULL THEN 1 END) AS Cast_Count,
       STRING_AGG(DISTINCT a.name, ', ') AS Cast_Names
FROM movie_hierarchy mh
LEFT JOIN cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN aka_name a ON c.person_id = a.person_id
WHERE mh.title IS NOT NULL
GROUP BY mh.movie_id, mh.title, mh.producer_name, mh.level
HAVING COUNT(DISTINCT a.name) > 0
ORDER BY COUNT(DISTINCT a.name) DESC, mh.title ASC;

-- Corner Cases
WITH distinct_titles AS (
    SELECT DISTINCT m.title, COALESCE(t.production_year, 0) AS production_year
    FROM aka_title m
    FULL OUTER JOIN title t ON m.id = t.id
    WHERE t.title IS NOT NULL OR m.title IS NOT NULL
), 
keyword_movie AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword IS NOT NULL
    GROUP BY mk.movie_id
)

SELECT dt.title,
       dt.production_year,
       COALESCE(km.keyword_count, 0) AS Total_Keywords,
       CASE 
           WHEN dt.production_year < 2000 THEN 'Classic'
           WHEN dt.production_year BETWEEN 2000 AND 2010 THEN 'Modern Classic'
           ELSE 'Recent'
       END AS Era_Classification
FROM distinct_titles dt
LEFT JOIN keyword_movie km ON dt.movie_id = km.movie_id
WHERE COALESCE(km.keyword_count, 0) > 5
ORDER BY dt.production_year DESC, dt.title;
