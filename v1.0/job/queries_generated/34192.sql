WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1 AS level
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
actor_roles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
movies_with_info AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        STRING_AGG(DISTINCT ak.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT ai.info, ', ') AS additional_info,
        ARRAY_AGG(DISTINCT ar.actor_name) AS actors,
        MAX(ar.actor_rank) AS max_actor_rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ak ON mk.keyword_id = ak.id
    LEFT JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        actor_roles ar ON mh.movie_id = ar.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    mwi.movie_id,
    mwi.title,
    mwi.production_year,
    COALESCE(mwi.keywords, 'No keywords') AS keywords,
    COALESCE(mwi.additional_info, 'No additional information') AS additional_info,
    COUNT(mwi.actors) AS total_actors,
    CASE 
        WHEN mwi.max_actor_rank IS NULL THEN 'No actors'
        ELSE CONCAT('Max actor position: ', mwi.max_actor_rank)
    END AS actor_position
FROM 
    movies_with_info mwi
LEFT JOIN 
    movie_info mi ON mwi.movie_id = mi.movie_id
WHERE 
    (mwi.production_year IS NOT NULL AND mwi.production_year > 2000) 
    OR (mwi.keywords IS NOT NULL AND mwi.keywords LIKE '%Action%')
GROUP BY 
    mwi.movie_id, mwi.title, mwi.production_year
ORDER BY 
    mwi.production_year DESC, mwi.title ASC;
