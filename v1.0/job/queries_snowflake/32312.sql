
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id  
),

ranked_cast AS (
    SELECT 
        ci.movie_id,
        an.name AS actor_name,
        rc.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order ASC) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        role_type rc ON ci.role_id = rc.id
),

movie_info_summary AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(mi.id) AS info_count, 
        LISTAGG(DISTINCT mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS info_details
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id, m.title
),

final_results AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(rk.actor_name, 'Unknown') AS primary_actor,
        COALESCE(info.info_count, 0) AS total_info_entries,
        COALESCE(info.info_details, 'No Info') AS info_contents,
        mh.level
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        ranked_cast rk ON mh.movie_id = rk.movie_id AND rk.role_rank = 1  
    LEFT JOIN 
        movie_info_summary info ON mh.movie_id = info.movie_id
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.primary_actor,
    f.total_info_entries,
    f.info_contents,
    f.level
FROM 
    final_results f
WHERE 
    f.production_year >= 2000  
ORDER BY 
    f.production_year DESC,
    f.title ASC;
