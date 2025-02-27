WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           1 AS depth 
    FROM aka_title m 
    WHERE m.production_year >= 2000
    
    UNION ALL
    
    SELECT m.id AS movie_id, 
           m.title, 
           mh.depth + 1 
    FROM movie_hierarchy mh 
    JOIN movie_link ml ON mh.movie_id = ml.movie_id 
    JOIN aka_title m ON ml.linked_movie_id = m.id 
    WHERE m.production_year >= 2000
), 
movie_details AS (
    SELECT 
        mt.title,
        mt.production_year,
        c.name AS character_name,
        a.name AS actor_name,
        COALESCE(mk.keyword, 'None') AS keyword,
        ct.kind AS company_type,
        COUNT(mc.company_id) AS company_count
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN char_name c ON c.imdb_id = a.imdb_id
    LEFT JOIN movie_companies mc ON mc.movie_id = mt.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = mt.id
    WHERE mt.production_year IS NOT NULL
    GROUP BY mt.title, mt.production_year, c.name, a.name, mk.keyword, ct.kind
)
SELECT 
    md.*,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.company_count DESC) as rank_by_company,
    RANK() OVER (ORDER BY md.production_year) AS year_rank,
    NTILE(4) OVER (ORDER BY md.company_count) as company_quartile
FROM movie_details md
JOIN movie_hierarchy mh ON mh.movie_id = md.movie_id
WHERE md.actor_name IS NOT NULL
  AND md.character_name IS NOT NULL
  AND md.production_year BETWEEN 2000 AND 2023
ORDER BY md.production_year, md.company_count DESC;
