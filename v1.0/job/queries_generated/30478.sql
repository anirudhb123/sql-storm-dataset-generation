WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(ml.linked_movie_id, 0) AS linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(ml.linked_movie_id, 0) AS linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(mr.role_count) AS average_roles,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    CASE 
        WHEN AVG(mr.role_count) > 5 THEN 'High' 
        WHEN AVG(mr.role_count) IS NULL THEN 'N/A' 
        ELSE 'Medium'
    END AS role_average_category,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS movie_rank
FROM 
    movie_hierarchy mh
LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id 
LEFT JOIN (
    SELECT 
        ci.movie_id,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
) mr ON mh.movie_id = mr.movie_id
LEFT JOIN aka_name ak ON ak.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = mh.movie_id)
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, movie_rank
LIMIT 50;
