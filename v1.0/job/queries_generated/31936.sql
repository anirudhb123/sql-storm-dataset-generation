WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    ARRAY_AGG(DISTINCT cn.name) AS company_names,
    AVG(COALESCE(mo.production_year, mo2.production_year)) AS avg_year_of_related_movies,
    COUNT(DISTINCT ci.id) AS total_cast_members,
    SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS named_roles_count,
    ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY mh.production_year DESC) AS rank_within_depth
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_title mo ON mo.id = ci.movie_id
LEFT JOIN 
    movie_link ml ON mh.movie_id = ml.movie_id
LEFT JOIN 
    aka_title mo2 ON ml.linked_movie_id = mo2.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth
HAVING 
    COUNT(DISTINCT ci.id) > 5
ORDER BY 
    mh.depth, avg_year_of_related_movies DESC;
