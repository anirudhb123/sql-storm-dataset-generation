
WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           m.phonetic_code, 
           1 AS level 
    FROM aka_title m 
    WHERE m.production_year >= 2000
    
    UNION ALL
    
    SELECT t.movie_id, 
           t.title, 
           t.production_year, 
           t.phonetic_code, 
           mh.level + 1 
    FROM movie_link l 
    JOIN movie_hierarchy mh ON l.movie_id = mh.movie_id
    JOIN aka_title t ON l.linked_movie_id = t.id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
    COUNT(DISTINCT CAST(c.person_role_id AS INTEGER)) AS role_count
FROM movie_hierarchy m
JOIN cast_info c ON m.movie_id = c.movie_id
JOIN aka_name a ON c.person_id = a.person_id
LEFT JOIN movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
WHERE 
    m.production_year >= 2000 
    AND a.name IS NOT NULL
    AND a.name <> ''
GROUP BY a.name, m.title, m.production_year
HAVING COUNT(DISTINCT c.id) > 1
ORDER BY m.production_year DESC, role_count DESC
LIMIT 100;
