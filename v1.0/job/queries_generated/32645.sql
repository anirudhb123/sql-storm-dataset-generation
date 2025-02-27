WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        lm.linked_movie_id,
        l.title,
        l.production_year,
        mh.depth + 1
    FROM 
        movie_link lm
    JOIN 
        aka_title l ON lm.linked_movie_id = l.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = lm.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    AVG(pi.info_length) AS avg_info_length,
    STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') AS cast_list,
    CASE 
        WHEN AVG(pi.info_length) IS NULL THEN 'No Info'
        WHEN AVG(pi.info_length) < 50 THEN 'Short Info'
        ELSE 'Detailed Info'
    END AS info_quality
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    (SELECT 
         person_id, 
         LENGTH(info) AS info_length 
     FROM 
         person_info 
     WHERE 
         info IS NOT NULL) pi ON pi.person_id = c.person_id
WHERE 
    mh.depth < 3
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    actor_count DESC, mh.production_year ASC
LIMIT 100;
