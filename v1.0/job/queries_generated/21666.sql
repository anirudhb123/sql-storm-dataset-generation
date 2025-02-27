WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year,
           0 AS level
    FROM aka_title m 
    WHERE m.production_year > 2000
  
    UNION ALL

    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year,
           mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON ml.movie_id = mh.movie_id 
    JOIN aka_title linked ON linked.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON mh.movie_id = m.id 
    WHERE mh.level < 3
), 

MovieDetails AS (
    SELECT a.title,
           a.production_year,
           COALESCE(GROUP_CONCAT(DISTINCT c.name), 'No Cast') AS cast_names,
           COUNT(DISTINCT k.keyword) AS keyword_count,
           ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT k.keyword) DESC) AS rank_by_keyword
    FROM MovieHierarchy a
    LEFT JOIN cast_info ci ON ci.movie_id = a.movie_id 
    LEFT JOIN aka_name c ON c.person_id = ci.person_id 
    LEFT JOIN movie_keyword mk ON mk.movie_id = a.movie_id 
    LEFT JOIN keyword k ON k.id = mk.keyword_id 
    GROUP BY a.title, a.production_year
)

SELECT md.title,
       md.production_year,
       md.cast_names,
       md.keyword_count,
       CASE 
           WHEN md.keyword_count > 5 THEN 'Popular'
           WHEN md.keyword_count BETWEEN 3 AND 5 THEN 'Moderate'
           ELSE 'Niche'
       END AS popularity_category,
       EXISTS (SELECT 1 
               FROM complete_cast cc 
               WHERE cc.movie_id = (SELECT id FROM aka_title WHERE title = md.title LIMIT 1) 
                 AND cc.status_id IS NULL) AS is_complete_cast_missing
FROM MovieDetails md
WHERE md.rank_by_keyword <= 10
ORDER BY md.production_year DESC, md.keyword_count DESC;

-- Add further complexity with a NOT EXISTS subquery checking for companies involved.
WITH CompaniesInvolved AS (
    SELECT DISTINCT mc.movie_id, 
           COALESCE(cn.name, 'Unknown Company') AS company_name
    FROM movie_companies mc 
    LEFT JOIN company_name cn ON mc.company_id = cn.id 
    WHERE mc.movie_id IN (SELECT movie_id FROM complete_cast)
)

SELECT md.title,
       md.production_year,
       md.cast_names,
       md.keyword_count,
       ci.company_name
FROM MovieDetails md
LEFT JOIN CompaniesInvolved ci ON md.movie_id = ci.movie_id
WHERE NOT EXISTS (SELECT 1 
                  FROM movie_info mi 
                  WHERE mi.movie_id = md.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis'))
ORDER BY md.production_year, md.keyword_count DESC;

