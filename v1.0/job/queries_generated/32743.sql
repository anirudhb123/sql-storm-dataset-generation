WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           COALESCE(mo.company_name, 'Unknown') AS company_name,
           1 AS level
    FROM aka_title m
    LEFT JOIN (
        SELECT mc.movie_id, c.name AS company_name
        FROM movie_companies mc
        JOIN company_name c ON mc.company_id = c.id
    ) mo ON m.id = mo.movie_id

    UNION ALL

    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           COALESCE(mo.company_name, 'Unknown') AS company_name,
           mh.level + 1
    FROM aka_title m
    JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
)

SELECT mh.title,
       mh.production_year,
       mh.company_name,
       COUNT(DISTINCT c.person_id) AS total_cast,
       AVG(CASE 
           WHEN pi.info IS NOT NULL THEN LENGTH(pi.info)
           ELSE 0 
       END) AS avg_info_length,
       STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
       SUM(CASE 
           WHEN mn.gender = 'F' THEN 1 
           ELSE 0 
       END) AS female_cast_count
FROM MovieHierarchy mh
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN cast_info c ON cc.subject_id = c.person_id
LEFT JOIN person_info pi ON c.person_id = pi.person_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN aka_name mn ON c.person_id = mn.person_id
WHERE mh.production_year >= 2000
GROUP BY mh.movie_id, mh.title, mh.production_year, mh.company_name
HAVING COUNT(DISTINCT c.person_id) > 0
ORDER BY mh.production_year DESC, total_cast DESC;

This query constructs a recursive common table expression (CTE) to create a hierarchy of movies, linking episodes to their parent series. It then aggregates data on the cast and associated information, including average information length and counts of female roles, while incorporating multiple joins, null handling, and string aggregation for a comprehensive performance benchmark.
