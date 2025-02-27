WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mcl.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link mcl ON mt.id = mcl.movie_id
    WHERE 
        mt.production_year = 2023
    
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mcl.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link mcl ON mh.linked_movie_id = mcl.movie_id
    JOIN 
        aka_title mt ON mcl.linked_movie_id = mt.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT ac.person_id) AS total_actors,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(CASE WHEN les.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_lead_roles,
    COUNT(DISTINCT CASE WHEN mcl.linked_movie_id IS NOT NULL THEN mcl.linked_movie_id END) AS total_linked_movies,
    ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ac.person_id) DESC) AS rank_by_actor_count,
    CASE 
        WHEN COUNT(DISTINCT ac.person_id) IS NULL THEN 'No Actors'
        ELSE NULL 
    END AS actor_status
FROM 
    movie_hierarchy m
JOIN 
    cast_info ac ON m.movie_id = ac.movie_id
JOIN 
    aka_name ak ON ac.person_id = ak.person_id
JOIN 
    aka_title at ON ac.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    role_type les ON ac.role_id = les.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, at.title, m.production_year
HAVING 
    COUNT(DISTINCT ac.person_id) > 0
ORDER BY 
    m.production_year DESC, total_actors DESC;
