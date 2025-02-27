WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
        JOIN aka_title at ON ml.linked_movie_id = at.id
        JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
), cast_details AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.role_id) AS role_count,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY a.name) AS actor_order
    FROM 
        cast_info ci
        JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id, a.name
), movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COALESCE(cd.actor_name, 'Unknown Actor') AS lead_actor,
    cd.role_count AS number_of_roles,
    CASE 
        WHEN mh.level > 1 THEN 'Sequel/Related Movie'
        ELSE 'Standalone Movie'
    END AS movie_type,
    COALESCE(mk.keywords, 'No Keywords') AS related_keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id AND cd.actor_order = 1
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year IS NOT NULL
ORDER BY 
    mh.production_year DESC, mh.movie_title;
