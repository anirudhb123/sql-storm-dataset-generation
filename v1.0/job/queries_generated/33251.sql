WITH RECURSIVE Actor_Hierarchy AS (
    SELECT c.person_id,
           ak.name AS actor_name,
           COUNT(DISTINCT cc.movie_id) AS movies_count,
           ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY COUNT(DISTINCT cc.movie_id) DESC) AS rn
    FROM cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    JOIN complete_cast cc ON c.movie_id = cc.movie_id
    GROUP BY c.person_id, ak.name

    UNION ALL

    SELECT ah.person_id,
           ah.actor_name,
           ah.movies_count,
           ROW_NUMBER() OVER (PARTITION BY ah.person_id ORDER BY ah.movies_count DESC) AS rn
    FROM Actor_Hierarchy ah
    JOIN cast_info ci ON ah.person_id = ci.person_id
    WHERE ah.rn <= 5
)

SELECT a.actor_name,
       a.movies_count,
       COALESCE(m.production_year, 'N/A') AS first_movie_year,
       STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM Actor_Hierarchy a
LEFT JOIN aka_title m ON a.movies_count > 5 AND a.person_id = m.movie_id
LEFT JOIN movie_keyword k ON m.id = k.movie_id
WHERE a.movies_count > 0
GROUP BY a.actor_name, a.movies_count, m.production_year
HAVING COUNT(DISTINCT m.id) > 2
ORDER BY a.movies_count DESC, a.actor_name
LIMIT 10;
