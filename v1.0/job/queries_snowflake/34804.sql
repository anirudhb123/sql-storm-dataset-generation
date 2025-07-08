
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        0 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = (
            SELECT MAX(production_year) 
            FROM aka_title
        )
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.level + 1,
        mh.movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ak.id AS actor_id,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(mk.keyword_id::text, ', ') WITHIN GROUP (ORDER BY mk.keyword_id) AS keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
detailed_movie_info AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        COALESCE(cd.actor_name, 'No Cast') AS main_actor,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        mh.level
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_details cd ON mh.movie_id = cd.movie_id AND cd.actor_rank = 1
    LEFT JOIN 
        movie_keywords mk ON mh.movie_id = mk.movie_id
)
SELECT 
    dmi.movie_id,
    dmi.movie_title,
    dmi.main_actor,
    dmi.keywords,
    dmi.level,
    CASE 
        WHEN dmi.level = 0 THEN 'Top Level Movie'
        WHEN dmi.level = 1 THEN 'Sequel/Prequel'
        ELSE 'Related Movie'
    END AS movie_relationship,
    COUNT(DISTINCT ci.person_id) AS total_cast_members
FROM 
    detailed_movie_info dmi
LEFT JOIN 
    cast_info ci ON dmi.movie_id = ci.movie_id
GROUP BY 
    dmi.movie_id, dmi.movie_title, dmi.main_actor, dmi.keywords, dmi.level
HAVING 
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY 
    dmi.level, dmi.movie_title;
