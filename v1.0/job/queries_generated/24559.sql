WITH RECURSIVE actor_hierarchy AS (
    SELECT c.person_id, a.name AS actor_name, 1 AS depth
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.movie_id IN (
        SELECT id FROM aka_title WHERE title LIKE '%Ghost%' 
        AND production_year >= 1990
    )
    
    UNION ALL

    SELECT c.person_id, a.name AS actor_name, h.depth + 1 AS depth
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN actor_hierarchy h ON c.movie_id IN (
        SELECT m.movie_id FROM complete_cast m WHERE m.subject_id = h.person_id
    )
)

SELECT 
    a.actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    MIN(t.production_year) AS first_appearance,
    MAX(t.production_year) AS last_appearance,
    AVG(EXTRACT(YEAR FROM CURRENT_DATE) - t.production_year) AS avg_years_since_release,
    CASE
        WHEN AVG(t.production_year) IS NULL THEN 'No data'
        WHEN AVG(t.production_year) < 2000 THEN 'Classic Actor'
        ELSE 'Modern Actor'
    END AS actor_category
FROM actor_hierarchy a
JOIN cast_info c ON a.person_id = c.person_id
JOIN aka_title t ON c.movie_id = t.id
LEFT JOIN movie_keyword mk ON mk.movie_id = c.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
GROUP BY a.actor_name
HAVING COUNT(DISTINCT c.movie_id) > 5
ORDER BY avg_years_since_release DESC
LIMIT 10
OFFSET 0;

WITH movie_rank AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS movie_position,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM aka_title m
    JOIN cast_info ci ON m.id = ci.movie_id
    WHERE m.production_year IS NOT NULL
    GROUP BY m.id
)

SELECT
    mr.movie_id,
    mr.title,
    mr.movie_position,
    mr.cast_count,
    COALESCE(dt.department_name, 'Unspecified') AS department_name
FROM movie_rank mr
LEFT JOIN movie_info mi ON mi.movie_id = mr.movie_id
LEFT JOIN (
    SELECT DISTINCT
        mi.movie_id,
        CASE 
            WHEN info LIKE '%action%' THEN 'Action'
            WHEN info LIKE '%drama%' THEN 'Drama'
            ELSE 'Other'
        END AS department_name
    FROM movie_info mi
    WHERE info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Genre%')
) dt ON dt.movie_id = mr.movie_id
WHERE mr.cast_count > 3
ORDER BY mr.movie_position, mr.cast_count DESC;

SELECT 
    m.title,
    COUNT(DISTINCT c.person_id) AS num_actors,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS num_notes,
    CASE 
        WHEN COUNT(DISTINCT c.person_id) > 10 THEN 'Ensemble Cast'
        WHEN COUNT(DISTINCT c.person_id) <= 3 THEN 'Limited Cast'
        ELSE 'Moderate Cast'
    END AS cast_type
FROM aka_title m
JOIN cast_info c ON m.id = c.movie_id
WHERE m.production_year BETWEEN 2000 AND 2023
GROUP BY m.title
HAVING COUNT(DISTINCT c.person_id) > 1 OR SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY num_actors DESC, num_notes DESC
LIMIT 5;
