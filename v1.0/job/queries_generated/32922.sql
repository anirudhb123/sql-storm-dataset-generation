WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.title IS NOT NULL
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    akn.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COALESCE(ci.nr_order, -1) AS actor_order,
    ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY COALESCE(ci.nr_order, -1)) AS ranked_order,
    COUNT(*) OVER (PARTITION BY mt.id) AS total_cast,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name) AS company_names
FROM 
    movie_hierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name akn ON ci.person_id = akn.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    (mh.production_year < 2000 OR mh.production_year IS NULL)
    AND akn.name IS NOT NULL
GROUP BY 
    akn.name, mt.title, mt.production_year, ci.nr_order
ORDER BY 
    mt.production_year DESC, actor_name;
