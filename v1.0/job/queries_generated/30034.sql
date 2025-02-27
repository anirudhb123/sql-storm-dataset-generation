WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id AS actor_id, ca.name AS actor_name, 1 AS level
    FROM cast_info ci
    JOIN aka_name ca ON ci.person_id = ca.person_id
    WHERE ci.movie_id IN (
        SELECT id 
        FROM aka_title 
        WHERE production_year >= 2000
    )
    
    UNION ALL
    
    SELECT ci.person_id, ca.name, ah.level + 1
    FROM cast_info ci
    JOIN aka_name ca ON ci.person_id = ca.person_id
    JOIN ActorHierarchy ah ON ci.movie_id = ah.actor_id
    WHERE ci.nr_order <> ah.level
)

SELECT 
    a.actor_id,
    a.actor_name,
    COUNT(DISTINCT ci.movie_id) AS movies_count,
    AVG(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) END) AS avg_movie_length,
    SUM(CASE WHEN ci.nr_order = 1 THEN 1 ELSE 0 END) AS lead_roles,
    ARRAY_AGG(DISTINCT kt.keyword) AS keywords,
    COALESCE(NULLIF(MAX(kt.keyword), ''), 'No Keywords') AS last_keyword,
    DENSE_RANK() OVER (PARTITION BY a.actor_id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
FROM 
    ActorHierarchy a
LEFT JOIN 
    cast_info ci ON a.actor_id = ci.person_id
LEFT JOIN 
    movie_info mi ON ci.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
GROUP BY 
    a.actor_id, a.actor_name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5
ORDER BY 
    actor_rank, a.actor_name;
