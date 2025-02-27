WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.note IS NULL OR mt.note = ''
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.depth < 3 -- Limit the depth of recursion
)

SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    COALESCE(y.info, 'No information available') AS additional_info,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY at.production_year DESC) AS latest_movie_rank,
    COUNT(DISTINCT k.keyword) AS keywords_count,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes,
    CASE
        WHEN c.nr_order IS NULL THEN 'Unknown Order'
        WHEN c.nr_order = 1 THEN 'Lead Role'
        ELSE 'Supporting Role'
    END AS role_description,
    COUNT(DISTINCT (SELECT movie_id FROM complete_cast cc WHERE cc.subject_id = a.id)) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info y ON at.id = y.movie_id AND y.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Synopsis' LIMIT 1
    )
LEFT JOIN 
    movie_info_idx mi ON at.id = mi.movie_id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    at.production_year BETWEEN 2000 AND 2023
AND 
    (c.note IS NULL OR c.note != 'Cameo') 
AND 
    (a.md5sum IS NOT NULL OR a.surname_pcode IS NOT NULL)
GROUP BY 
    a.id, at.id, y.info, c.nr_order
HAVING 
    COUNT(DISTINCT k.keyword) > 0
ORDER BY 
    latest_movie_rank, keywords_count DESC;

-- This query explores various advanced SQL features such as recursive CTEs for movie hierarchies,
-- window functions for ranking movies, conditional aggregations, NULL handling with COALESCE,
-- filtering through complicated predicates with multiple outer joins and subqueries,
-- and contextually sensitive groupings and sorting.
