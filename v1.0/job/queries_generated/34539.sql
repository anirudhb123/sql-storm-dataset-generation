WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        0 AS generation,
        NULL::integer AS parent_actor_id
    FROM aka_name a
    WHERE a.id IN (SELECT DISTINCT person_id FROM cast_info c WHERE c.movie_id IN (SELECT movie_id FROM aka_title WHERE production_year = 2020))
    
    UNION ALL
    
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ah.generation + 1 AS generation,
        ah.actor_id AS parent_actor_id
    FROM aka_name a
    JOIN cast_info c ON c.person_id = a.id
    JOIN actor_hierarchy ah ON ah.actor_id = c.movie_id
)
SELECT 
    a.actor_name,
    COUNT(DISTINCT c.movie_id) AS number_of_movies,
    STRING_AGG(DISTINCT t.title, ', ') AS titles,
    MAX(a.generation) AS max_generation
FROM actor_hierarchy a
JOIN cast_info c ON a.actor_id = c.person_id
JOIN aka_title t ON c.movie_id = t.id
WHERE a.actor_name IS NOT NULL
GROUP BY a.actor_name
HAVING COUNT(DISTINCT c.movie_id) > 5
ORDER BY number_of_movies DESC
LIMIT 10;

-- Performance Benchmarking with Window Function and NULL Logic
SELECT
    t.title,
    COUNT(DISTINCT c.person_id) AS cast_count,
    AVG(CASE WHEN p.info IS NOT NULL THEN 1 ELSE 0 END) AS has_person_info_ratio,
    COUNT(DISTINCT CASE WHEN c.note IS NOT NULL THEN c.person_id END) OVER (PARTITION BY t.id) AS cast_with_notes
FROM aka_title t
JOIN cast_info c ON t.id = c.movie_id
LEFT JOIN person_info p ON c.person_id = p.person_id
GROUP BY t.title
HAVING COUNT(DISTINCT c.person_id) > 3
ORDER BY cast_count DESC, has_person_info_ratio DESC;

-- Outer Join and Set Operator Example
SELECT 
    t.title,
    wc.company_name,
    COUNT(DISTINCT c.person_id) AS cast_count
FROM aka_title t
LEFT JOIN movie_companies mc ON t.id = mc.movie_id
LEFT JOIN company_name wc ON mc.company_id = wc.id
JOIN cast_info c ON t.id = c.movie_id
GROUP BY t.title, wc.company_name

UNION ALL

SELECT 
    'No Company' AS title,
    'N/A' AS company_name,
    COUNT(DISTINCT c.person_id) AS cast_count
FROM aka_title t
JOIN cast_info c ON t.id = c.movie_id
WHERE t.id NOT IN (SELECT DISTINCT mc.movie_id FROM movie_companies mc)
GROUP BY 'No Company';

-- Complex Predicate Example
SELECT 
    t.title,
    t.production_year,
    COUNT(DISTINCT c.person_id) AS cast_count,
    AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_cast_note_existence
FROM aka_title t
JOIN cast_info c ON t.id = c.movie_id
WHERE t.production_year BETWEEN 2000 AND 2023
    AND (t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Film%') OR t.note IS NULL)
GROUP BY t.title, t.production_year
ORDER BY CAST(t.production_year AS INTEGER) DESC, cast_count DESC;
