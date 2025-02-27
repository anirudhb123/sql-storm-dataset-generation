WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        CONCAT( mh.title, ' -> ', m.title) AS title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title AS m
    INNER JOIN 
        movie_hierarchy AS mh ON m.episode_of_id = mh.movie_id
)
,
cast_with_roles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON a.person_id = c.person_id
    JOIN 
        role_type AS r ON r.id = c.role_id
)
,
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ' ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cwr.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(cwr.role_name, 'Unknown Role') AS role_name,
    mk.keywords,
    COUNT(DISTINCT cwr.actor_name) OVER (PARTITION BY mh.movie_id) AS actor_count,
    ARRAY_AGG(DISTINCT cwr.role_name) AS role_list
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    cast_with_roles AS cwr ON cwr.movie_id = mh.movie_id
LEFT JOIN 
    movie_keywords AS mk ON mk.movie_id = mh.movie_id
WHERE 
    mh.production_year >= 2000
    AND (cwr.role_name IS NULL OR LENGTH(cwr.role_name) > 0)
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, cwr.actor_name, cwr.role_name, mk.keywords
HAVING 
    COUNT(cwr.actor_name) IS NULL OR COUNT(cwr.actor_name) > 2
ORDER BY 
    mh.production_year DESC, mh.title;
