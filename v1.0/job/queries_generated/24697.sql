WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    CASE 
        WHEN NULLIF(mk.keyword, '') IS NOT NULL THEN mk.keyword 
        ELSE 'No Keywords' 
    END AS movie_keyword,
    COUNT(DISTINCT cc.id) OVER (PARTITION BY a.id) AS role_count,
    AVG(CASE 
        WHEN pi.info IS NOT NULL THEN LENGTH(pi.info) 
        ELSE 0 
    END) AS avg_person_info_length,
    DENSE_RANK() OVER (PARTITION BY mt.production_year ORDER BY mh.depth DESC) AS movie_rank_by_year
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id AND mi.note IS NULL
LEFT JOIN 
    person_info pi ON pi.person_id = a.person_id
LEFT JOIN 
    movie_hierarchy mh ON mt.id = mh.movie_id
WHERE 
    a.md5sum IS NOT NULL
    AND (mt.production_year >= 2000 OR NOT EXISTS (SELECT 1 FROM movie_companies mc WHERE mc.movie_id = mt.id))
ORDER BY 
    movie_rank_by_year, actor_name ASC;

This query includes a recursive CTE to create a movie hierarchy, several outer joins to associate actors with their movies, and calculations to derive averages and counts based on the joined data. It incorporates NULL logic to handle cases where specific fields may not exist, different predicates in the WHERE clause, and utilizes window functions for ranking and counting. The use of `NULLIF` ensures we handle empty keywords sensibly, and diverse joins exemplify complex relationships within the provided schema.
