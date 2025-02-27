WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id,
        a.name,
        ci.movie_id,
        1 AS depth
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.role_id = (SELECT id FROM role_type WHERE role = 'Actor')
    
    UNION ALL

    SELECT 
        ci.person_id,
        a.name,
        ci.movie_id,
        ah.depth + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        actor_hierarchy ah ON ci.movie_id = ah.movie_id
    WHERE 
        ci.role_id = (SELECT id FROM role_type WHERE role = 'Actor')
)

SELECT 
    COALESCE(ak.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    AVG(COALESCE(mi.info_type_id, -1)) AS avg_info_type,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    MAX(w.rank) OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS highest_rank
FROM 
    actor_hierarchy ah
JOIN 
    cast_info ci ON ah.person_id = ci.person_id
JOIN 
    aka_name ak ON ah.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON ci.movie_id = mi.movie_id 
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
LEFT JOIN 
    (SELECT 
         m.movie_id, 
         RANK() OVER (PARTITION BY m.movie_id ORDER BY COUNT(DISTINCT ci.person_id)) AS rank 
     FROM 
         cast_info ci
     JOIN 
         movie_companies mc ON ci.movie_id = mc.movie_id
     GROUP BY 
         m.movie_id) w ON ci.movie_id = w.movie_id
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5 OR 
    MAX(COALESCE(mi.info_type_id, -1)) < 0
ORDER BY 
    highest_rank DESC, 
    actor_name ASC
LIMIT 50;
