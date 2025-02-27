WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level,
        ARRAY[t.title] AS path
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1,
        path || t.title
    FROM 
        aka_title t
    INNER JOIN 
        movie_hierarchy mh ON t.episode_of_id = mh.movie_id
),
ranked_cast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.person_role_id,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
),
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)

SELECT 
    mh.title AS movie_title,
    mh.production_year,
    rc.actor_rank,
    akn.name AS actor_name,
    COALESCE(mkw.keywords, '{}') AS keywords,
    STRING_AGG(DISTINCT rc.role_id::TEXT, ', ') AS roles,
    CASE 
        WHEN rc.actor_rank = 1 THEN 'Lead Actor' 
        ELSE 'Supporting Actor' 
    END AS actor_category
FROM 
    movie_hierarchy mh
LEFT JOIN 
    ranked_cast rc ON mh.movie_id = rc.movie_id
LEFT JOIN 
    aka_name akn ON rc.person_id = akn.person_id
LEFT JOIN 
    movies_with_keywords mkw ON mh.movie_id = mkw.movie_id
WHERE 
    mh.level = 1
GROUP BY 
    mh.movie_id, rc.actor_rank, akn.name, mkw.keywords
ORDER BY 
    mh.production_year DESC, actor_rank
LIMIT 100;

