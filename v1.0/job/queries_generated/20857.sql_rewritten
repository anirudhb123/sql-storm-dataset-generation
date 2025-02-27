WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 3  
),
actor_info AS (
    SELECT 
        ak.name,
        ci.movie_id,
        ci.person_id,
        COUNT(ci.role_id) AS roles_count,
        ROW_NUMBER() OVER(PARTITION BY ci.person_id ORDER BY COUNT(ci.role_id) DESC) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL 
        AND ak.name <> ''
    GROUP BY 
        ak.name, ci.movie_id, ci.person_id
),
keyword_details AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ai.name AS actor_name,
    ai.roles_count,
    kd.keywords,
    COALESCE(ai.roles_count * 1.0 / NULLIF(mh.level, 0), 0) AS average_roles_per_link_level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    actor_info ai ON mh.movie_id = ai.movie_id AND ai.role_rank = 1
LEFT JOIN 
    keyword_details kd ON mh.movie_id = kd.movie_id
WHERE 
    mh.level > 0
ORDER BY 
    average_roles_per_link_level DESC, mh.production_year DESC
LIMIT 100;