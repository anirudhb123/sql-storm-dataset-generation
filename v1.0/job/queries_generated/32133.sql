WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        ARRAY[mt.id] AS path
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        mh.path || e.id
    FROM
        aka_title e
    JOIN
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
)

SELECT
    ak.name AS actor_name,
    at.title AS movie_title,
    EXTRACT(YEAR FROM CURRENT_DATE) - at.production_year AS years_since_release,
    COUNT(DISTINCT cc.id) OVER (PARTITION BY ak.person_id) AS total_movies,
    CASE
        WHEN ak.name IS NULL THEN 'Unknown Actor'
        ELSE ak.name
    END AS safe_actor_name,
    COALESCE(NULLIF(k.keyword, ''), 'No Keywords') AS movie_keyword,
    mn.info AS movie_info,
    COALESCE(mct.kind, 'N/A') AS company_type

FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_type mct ON mc.company_type_id = mct.id
LEFT JOIN 
    movie_info idx ON at.id = idx.movie_id AND idx.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = at.id

WHERE 
    at.production_year BETWEEN (EXTRACT(YEAR FROM CURRENT_DATE) - 5) AND (EXTRACT(YEAR FROM CURRENT_DATE) - 1)
    AND ak.name IS NOT NULL

ORDER BY 
    years_since_release DESC, 
    ak.name;

