WITH RECURSIVE actor_tree AS (
    SELECT c.person_id, c.movie_id, 1 AS depth
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name LIKE '%Smith%'  -- filtering actors with surname 'Smith'
    
    UNION ALL
    
    SELECT c.person_id, c.movie_id, at.depth + 1
    FROM cast_info c
    INNER JOIN actor_tree at ON c.movie_id = at.movie_id
    INNER JOIN aka_name a ON c.person_id = a.person_id
    WHERE at.depth < 3  -- limit the depth to 3 for recursion
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    count(DISTINCT c.id) AS total_cast_members,
    max(t.production_year) AS latest_movie_year,
    string_agg(DISTINCT k.keyword, ', ') AS associated_keywords,
    ROW_NUMBER() OVER(PARTITION BY a.name ORDER BY count(c.id) DESC) AS actor_ranking
FROM actor_tree at
JOIN aka_name a ON at.person_id = a.person_id
JOIN aka_title t ON at.movie_id = t.movie_id
LEFT JOIN cast_info c ON c.movie_id = t.id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
GROUP BY a.name, t.title
HAVING max(t.production_year) > 2000  -- Only consider movies produced after year 2000
ORDER BY actor_ranking, total_cast_members DESC, latest_movie_year DESC;

