
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        ep.id AS movie_id,
        ep.title,
        ep.production_year,
        mh.depth + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title ep
    JOIN 
        movie_hierarchy mh ON ep.episode_of_id = mh.movie_id
),

detailed_cast AS (
    SELECT 
        ca.movie_id,
        ak.name AS actor_name,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS role_order
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    JOIN 
        role_type r ON ca.role_id = r.id
),

movies_with_keyword AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id, mt.title
),

cast_summary AS (
    SELECT 
        d.movie_id,
        COUNT(d.actor_name) AS actor_count,
        LISTAGG(d.actor_name, ', ') AS actor_list
    FROM 
        detailed_cast d
    GROUP BY 
        d.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    COALESCE(cs.actor_count, 0) AS actor_count,
    COALESCE(cs.actor_list, 'No actors') AS actor_list,
    mwk.keywords,
    CASE 
        WHEN mh.depth = 1 THEN 'Main Movie'
        ELSE 'Episode'
    END AS movie_type
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    movies_with_keyword mwk ON mh.movie_id = mwk.movie_id
ORDER BY 
    mh.production_year DESC, mh.depth, mh.title;
