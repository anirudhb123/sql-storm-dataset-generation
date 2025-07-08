WITH RECURSIVE actor_hierarchy AS (
    SELECT ci.person_id, ci.movie_id, 
           ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY ci.nr_order) AS role_sequence
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
),

use_of_actors AS (
    SELECT ak.person_id, 
           COUNT(DISTINCT ah.movie_id) AS total_movies,
           MAX(ah.role_sequence) AS max_role_sequence
    FROM aka_name ak
    LEFT JOIN actor_hierarchy ah ON ak.person_id = ah.person_id
    GROUP BY ak.person_id
),

qualified_actors AS (
    SELECT ua.person_id, ua.total_movies, ua.max_role_sequence,
           ROW_NUMBER() OVER (ORDER BY ua.total_movies DESC, ua.max_role_sequence DESC) AS ranking
    FROM use_of_actors ua
    WHERE ua.total_movies > 5 AND ua.max_role_sequence IS NOT NULL
)

SELECT ak.name, q.total_movies, q.max_role_sequence
FROM qualified_actors q
JOIN aka_name ak ON q.person_id = ak.person_id
LEFT JOIN movie_info mi ON mi.movie_id IN (
    SELECT mc.movie_id FROM movie_companies mc 
    WHERE mc.company_id IN (
        SELECT cn.id FROM company_name cn
        WHERE cn.country_code = 'USA'
    )
)
AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office' LIMIT 1)
AND (mi.info IS NOT NULL AND mi.info NOT LIKE '%N/A%')
WHERE q.ranking <= 10
ORDER BY q.total_movies DESC;