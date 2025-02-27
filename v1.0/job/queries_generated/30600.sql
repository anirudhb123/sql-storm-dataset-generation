WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.movie_title,
    mt.production_year,
    (
        SELECT GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword)
        FROM movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
        WHERE mk.movie_id = mt.id
    ) AS keywords,
    ARRAY_AGG(DISTINCT cn.name) AS companies,
    COUNT(DISTINCT c.id) AS cast_member_count,
    ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS rank
FROM 
    movie_hierarchy mh
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    cast_info c ON mt.id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    mt.production_year IS NOT NULL
GROUP BY 
    ak.name, mt.movie_title, mt.production_year
HAVING 
    COUNT(DISTINCT c.id) > 0
    AND MAX(mh.level) < 3
ORDER BY 
    mt.production_year DESC, rank;
