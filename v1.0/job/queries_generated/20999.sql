WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        NULL::text AS parent_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        linked.title AS title,
        linked.production_year,
        linked.kind_id,
        mh.title AS parent_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title linked ON ml.linked_movie_id = linked.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(NULLIF(k.keyword, ''), 'No Keywords') AS keyword,
    CASE 
        WHEN ci.note IS NOT NULL THEN 'Role noted: ' || ci.note
        ELSE 'Role unspecified'
    END AS role_note,
    string_agg(DISTINCT co.name, ', ') FILTER (WHERE co.name IS NOT NULL) AS company_names,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.production_year DESC) AS ranking_level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    mh.production_year IS DISTINCT FROM 2000 -- Excludes movies from the year 2000
    AND (ci.role_id IS NULL OR ci.nr_order < 3) -- Include only leading roles or no role
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, k.keyword, ci.note
ORDER BY 
    mh.production_year DESC, mh.title;
This query creates a recursive common table expression (CTE) `movie_hierarchy` to handle movies and their relationships. It retrieves titles, production years, keywords, roles, and associated companies while also performing various NULL checks, string manipulations, and aggregations. It excludes specific years and limits roles based on defined criteria, offering insights into movie connections and relationships. The use of window functions allows for advanced ranking, providing additional benchmarking capabilities.
