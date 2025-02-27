WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL -- Base case: select only root movies

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title AS movie_title,
        et.production_year,
        mh.level + 1 -- Increase the level for each recursive call
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id -- Recursive case: find episodes of the movies
)

SELECT 
    cat.name AS actor_name,
    mt.movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT cct.kind, ', ') AS company_types,
    SUM(CASE 
            WHEN pi.info IS NULL THEN 0 
            ELSE LENGTH(pi.info) 
        END) AS total_info_length,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY LENGTH(cat.name) DESC) AS name_rank,
    CASE 
        WHEN MAX(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END) = 1 THEN 'Has Info' 
        ELSE 'No Info' 
    END AS info_status
FROM 
    movie_hierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name cat ON ci.person_id = cat.person_id 
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type cct ON mc.company_type_id = cct.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
WHERE 
    mh.production_year IS NOT NULL 
    AND (cat.name ILIKE '%John%' OR cat.name ILIKE '%Doe%') -- Example filtering by actor name
GROUP BY 
    cat.name, 
    mh.movie_id, 
    mh.movie_title, 
    mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0  -- Ensure at least one company is associated
ORDER BY 
    mh.production_year DESC, 
    name_rank;
