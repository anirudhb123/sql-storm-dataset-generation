WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND mt.production_year IS NOT NULL
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    ak.name AS actor_name,
    COUNT(DISTINCT mc.company_id) AS company_count,
    CASE 
        WHEN mh.level > 1 THEN 'Sequel'
        ELSE 'Original'
    END AS movie_type,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank_by_companies
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, ak.name, mh.level
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    mh.production_year DESC, rank_by_companies ASC;
