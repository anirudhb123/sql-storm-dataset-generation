WITH RECURSIVE movie_hierarchy AS (
    -- Base case: selecting all movies along with their production year
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt

    UNION ALL

    -- Recursive case: getting sequels or related movies based on links
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.movie_id AS parent_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    COALESCE(yr.year, 'Unknown') AS release_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    SUM(CASE WHEN cc.kind = 'Lead' THEN 1 ELSE 0 END) AS lead_role_count,
    MAX(CASE WHEN mk.info LIKE '%Oscar%' THEN 'Yes' ELSE 'No' END) AS won_oscar
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    comp_cast_type cc ON ci.person_role_id = cc.id
LEFT JOIN 
    (SELECT DISTINCT production_year 
     FROM aka_title 
     WHERE production_year IS NOT NULL) yr ON mt.production_year = yr.production_year

WHERE 
    mt.production_year IS NOT NULL 
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, mt.title, yr.year
ORDER BY 
    keyword_count DESC, lead_role_count DESC
LIMIT 100;

-- This query retrieves detailed statistics about movies, actors, and related information.
