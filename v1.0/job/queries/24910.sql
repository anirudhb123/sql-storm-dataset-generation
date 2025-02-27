
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_title_id,
        mt.title,
        mt.production_year,
        1 AS hierarchy_level,
        mt.id AS root_movie_id,
        CAST(mt.title AS VARCHAR(1000)) AS full_path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        atl.title,
        atl.production_year,
        mh.hierarchy_level + 1,
        mh.root_movie_id,
        CAST(mh.full_path || ' -> ' || atl.title AS VARCHAR(1000))
    FROM 
        movie_link ml
    JOIN 
        aka_title atl ON ml.linked_movie_id = atl.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_title_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    mh.hierarchy_level,
    mh.full_path,
    COUNT(DISTINCT mc.company_id) AS production_companies_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mh.hierarchy_level DESC) AS movie_rank
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_title_id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_title_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    aka_title at ON mh.movie_title_id = at.id
GROUP BY 
    ak.name, at.title, mh.production_year, mh.hierarchy_level, mh.full_path, ak.person_id
HAVING 
    COUNT(DISTINCT mc.company_id) >= 2
ORDER BY 
    movie_era DESC, movie_rank ASC;
