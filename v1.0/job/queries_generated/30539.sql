WITH RECURSIVE ActorHierarchy AS (
    SELECT ca.person_id AS actor_id, 
           ca.movie_id, 
           1 AS depth,
           ak.name AS actor_name
    FROM cast_info ca
    JOIN aka_name ak ON ca.person_id = ak.person_id
    WHERE ak.name IS NOT NULL
    
    UNION ALL
    
    SELECT ca.person_id AS actor_id, 
           ca.movie_id, 
           ah.depth + 1,
           ak.name AS actor_name
    FROM cast_info ca
    JOIN aka_name ak ON ca.person_id = ak.person_id
    JOIN ActorHierarchy ah ON ca.movie_id = ah.movie_id
    WHERE ak.name IS NOT NULL AND ah.actor_id <> ca.person_id
)

SELECT 
    ah.actor_name,
    m.title,
    COUNT(DISTINCT ca.person_id) AS co_star_count,
    MAX(CASE WHEN m.production_year IS NOT NULL THEN m.production_year ELSE 0 END) AS most_recent_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END) AS awards_info,
    RANK() OVER (PARTITION BY ah.movie_id ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS star_rank
FROM 
    ActorHierarchy ah
JOIN 
    complete_cast cc ON ah.movie_id = cc.movie_id
JOIN 
    title m ON ah.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info pi ON ah.actor_id = pi.person_id
LEFT JOIN 
    cast_info ca ON ca.movie_id = ah.movie_id
GROUP BY 
    ah.actor_name, m.title, ah.movie_id
HAVING 
    COUNT(DISTINCT ca.person_id) > 1 AND
    MAX(CASE WHEN m.production_year IS NOT NULL THEN m.production_year ELSE 0 END) > 2000
ORDER BY 
    co_star_count DESC, most_recent_year DESC;
