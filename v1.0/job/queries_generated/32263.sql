WITH RECURSIVE ActorHierarchy AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        0 AS level
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.movie_id IN (
        SELECT movie_id 
        FROM aka_title 
        WHERE production_year = 2023
    )
    
    UNION ALL
    
    SELECT
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN ActorHierarchy ah ON c.movie_id = ah.person_id
)

SELECT
    movie.title AS movie_title,
    COUNT(DISTINCT c.person_id) AS total_actors,
    ARRAY_AGG(DISTINCT a.actor_name) AS actor_names,
    AVG(CASE WHEN m.company_id IS NOT NULL THEN 1 ELSE 0 END) AS average_companies_inv,
    MAX(m.production_year) AS most_recent_year,
    COALESCE(MAX(k.keyword), 'N/A') AS primary_keyword,
    SUM(CASE WHEN pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'awards') THEN 1 ELSE 0 END) AS award_count,
    ROW_NUMBER() OVER (PARTITION BY movie.title ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_ranking
FROM aka_title movie
LEFT JOIN cast_info c ON movie.movie_id = c.movie_id
LEFT JOIN aka_name a ON c.person_id = a.person_id
LEFT JOIN movie_companies m ON movie.movie_id = m.movie_id
LEFT JOIN movie_keyword mk ON movie.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN person_info pi ON c.person_id = pi.person_id
WHERE movie.production_year IS NOT NULL
AND movie.title LIKE '%Action%'
GROUP BY movie.title
HAVING COUNT(DISTINCT c.person_id) > 2
ORDER BY total_actors DESC, movie_title
LIMIT 10;
