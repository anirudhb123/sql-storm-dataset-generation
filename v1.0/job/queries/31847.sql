WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::INTEGER AS parent_id,
        0 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM 
        aka_title AS m
    JOIN 
        movie_hierarchy AS mh ON mh.movie_id = m.episode_of_id
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN 
        role_type AS rt ON ci.role_id = rt.id
),
movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword AS mk
    GROUP BY 
        mk.movie_id
),
movie_info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') FILTER (WHERE mi.info IS NOT NULL) AS info_details
    FROM 
        movie_info AS mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    COALESCE(mid.info_details, 'No details available') AS info_details,
    ARRAY_AGG(cwr.actor_name ORDER BY cwr.actor_rank) AS actors
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    movie_keyword_counts AS mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_info_details AS mid ON mh.movie_id = mid.movie_id
LEFT JOIN 
    cast_with_roles AS cwr ON mh.movie_id = cwr.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mk.keyword_count, mid.info_details
ORDER BY 
    mh.production_year DESC, mh.title ASC;
