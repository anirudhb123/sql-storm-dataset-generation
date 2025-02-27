WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.production_year = (SELECT MAX(production_year) FROM aka_title)
  
    UNION ALL
  
    SELECT m.id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
person_roles AS (
    SELECT c.person_id, c.movie_id, r.role AS role_name,
           ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY c.nr_order) AS role_rank
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    WHERE r.role NOT LIKE '%Extra%'
),
company_info AS (
    SELECT DISTINCT cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind IS NOT NULL
),
keyword_info AS (
    SELECT k.keyword, COUNT(mk.movie_id) AS movie_count
    FROM keyword k
    JOIN movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY k.keyword
    HAVING COUNT(mk.movie_id) > 1
),
movie_details AS (
    SELECT a.id AS movie_id, a.title, a.production_year, co.company_name,
           ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS movie_rank
    FROM aka_title a
    LEFT JOIN movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN company_info co ON mc.company_id = (SELECT id FROM company_name ORDER BY RANDOM() LIMIT 1)
)
SELECT mh.movie_id, mh.title, mh.production_year,
       ARRAY_AGG(DISTINCT pr.role_name ORDER BY pr.role_rank) AS roles,
       COALESCE(ki.keyword, 'No Keywords') AS keywords,
       CASE WHEN COUNT(DISTINCT ci.company_name) > 1 THEN 'Multiple Companies' ELSE 'Single Company' END AS company_count_status
FROM movie_hierarchy mh
LEFT JOIN person_roles pr ON mh.movie_id = pr.movie_id
LEFT JOIN movie_details md ON mh.movie_id = md.movie_id
LEFT JOIN keyword_info ki ON mh.movie_id = (SELECT movie_id FROM movie_keyword WHERE keyword_id = (SELECT id FROM keyword ORDER BY RANDOM() LIMIT 1))
LEFT JOIN company_info ci ON mh.movie_id = (SELECT movie_id FROM movie_companies ORDER BY RANDOM() LIMIT 1)
GROUP BY mh.movie_id, mh.title, mh.production_year, ki.keyword
HAVING COUNT(DISTINCT pr.person_id) > 0
ORDER BY mh.production_year DESC, mh.title;
