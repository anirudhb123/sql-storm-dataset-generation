
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        CAST(CONCAT(mh.path, ' -> ', mt.title) AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    INNER JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_with_role AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    INNER JOIN 
        role_type rt ON ci.role_id = rt.id
),
movie_keyword_cte AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_summary AS (
    SELECT 
        h.movie_id,
        h.title,
        h.production_year,
        COALESCE(ak.actor_count, 0) AS actor_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(rt.max_role_depth, 0) AS max_role_depth
    FROM 
        movie_hierarchy h
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(DISTINCT actor_name) AS actor_count
        FROM 
            cast_with_role
        GROUP BY 
            movie_id
    ) ak ON h.movie_id = ak.movie_id
    LEFT JOIN (
        SELECT 
            movie_id,
            MAX(actor_order) AS max_role_depth
        FROM 
            cast_with_role
        GROUP BY 
            movie_id
    ) rt ON h.movie_id = rt.movie_id
    LEFT JOIN 
        movie_keyword_cte mk ON h.movie_id = mk.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.actor_count,
    ms.keywords,
    CONCAT('Level ', CAST(ms.max_role_depth AS VARCHAR)) AS role_depth_description,
    CASE 
        WHEN ms.actor_count > 5 THEN 'Popular Movie'
        WHEN ms.actor_count BETWEEN 3 AND 5 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS popularity_category
FROM 
    movie_summary ms
ORDER BY 
    ms.production_year DESC, ms.actor_count DESC;
