WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, 
           a.name, 
           1 AS level
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE ci.movie_id IN (
        SELECT mt.movie_id
        FROM movie_info mt
        JOIN info_type it ON mt.info_type_id = it.id
        WHERE it.info ILIKE '%Academy Award%'
    )
    
    UNION ALL
    
    SELECT ci.person_id, 
           a.name, 
           ah.level + 1
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN ActorHierarchy ah ON ci.movie_id = (
        SELECT mc.movie_id
        FROM movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
        WHERE cn.country_code = 'USA'
    )
)
SELECT ah.name,
       COUNT(DISTINCT ci.movie_id) AS movie_count,
       STRING_AGG(DISTINCT title.title, ', ') AS movies,
       RANK() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank
FROM ActorHierarchy ah
JOIN cast_info ci ON ah.person_id = ci.person_id
JOIN title ON ci.movie_id = title.id
GROUP BY ah.name
HAVING COUNT(DISTINCT ci.movie_id) > 1
ORDER BY movie_count DESC, ah.name ASC
LIMIT 10;
