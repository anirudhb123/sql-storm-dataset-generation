WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3  -- limiting recursion to 3 levels 
),
actor_info AS (
    SELECT 
        a.person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        ARRAY_AGG(DISTINCT co.name) AS company_names,
        SUM(CASE WHEN ci.note LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies AS mc ON ci.movie_id = mc.movie_id
    LEFT JOIN 
        company_name AS co ON mc.company_id = co.id
    GROUP BY 
        a.person_id, ak.name
)
SELECT 
    mh.title,
    mh.production_year,
    COALESCE(ai.actor_name, 'Unknown Actor') AS actor_name,
    ai.total_movies,
    ai.lead_roles,
    CASE 
        WHEN ai.total_movies IS NULL THEN 'No Roles'
        WHEN ai.lead_roles > 0 THEN CONCAT('Lead in ', ai.lead_roles, ' movies')
        ELSE 'Supporting Role'
    END AS role_description
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    actor_info AS ai ON mh.movie_id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = ai.person_id)
WHERE 
    mh.production_year > (
        SELECT AVG(production_year) FROM aka_title
    )
ORDER BY 
    mh.production_year DESC,
    ai.total_movies DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;

-- This query demonstrates a range of SQL features:
-- 1. CTEs: using recursive CTE for movie hierarchy and another for aggregated actor info.
-- 2. Aggregation: using COUNT, ARRAY_AGG, and SUM.
-- 3. Conditionals: using CASE statements to create a role description.
-- 4. LEFT JOINs and COALESCE for handling potentially missing data.
-- 5. Correlated subqueries to dynamically calculate averages and filter results.
-- 6. Handling NULLs in ordering by positioning NULL values last.
