
WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ca.person_id AS actor_id,
        ct.kind AS role,
        1 AS level
    FROM 
        cast_info ca
    INNER JOIN 
        comp_cast_type ct ON ca.person_role_id = ct.id
    WHERE 
        ca.nr_order = 1  

    UNION ALL

    SELECT 
        ca.person_id,
        CONCAT(ct.kind, ' -> ', ah.role) AS role,
        ah.level + 1
    FROM 
        cast_info ca
    INNER JOIN 
        comp_cast_type ct ON ca.person_role_id = ct.id
    INNER JOIN 
        actor_hierarchy ah ON ca.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ah.actor_id)
    WHERE 
        ca.nr_order > 1
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT ca.movie_id) AS movie_count,
    LISTAGG(DISTINCT CONCAT(t.title, ' (', t.production_year, ')'), ', ') WITHIN GROUP (ORDER BY t.title) AS movies,
    (SELECT AVG(m.production_year) 
     FROM aka_title m 
     JOIN movie_keyword mk ON m.movie_id = mk.movie_id 
     WHERE mk.keyword_id IN (
         SELECT k.id FROM keyword k WHERE k.keyword = 'Award'
     )
    ) AS avg_award_year,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(DISTINCT ca.movie_id) DESC) AS rank
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ca ON ak.person_id = ca.person_id
LEFT JOIN 
    title t ON ca.movie_id = t.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT ca.movie_id) > 5
ORDER BY 
    movie_count DESC, rank ASC
LIMIT 10;
