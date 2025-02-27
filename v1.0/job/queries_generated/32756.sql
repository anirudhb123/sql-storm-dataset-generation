WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS character_role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
movie_info_with_keywords AS (
    SELECT 
        mt.*, 
        STRING_AGG(k.keyword, ', ') AS keywords 
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id
),
filtered_movies AS (
    SELECT 
        mh.*,
        ci.actor_name,
        ci.character_role,
        mwk.keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_with_roles ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        movie_info_with_keywords mwk ON mh.movie_id = mwk.movie_id
    WHERE 
        ci.actor_name IS NOT NULL 
        OR mwk.keywords IS NOT NULL
)

SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.actor_name, 'Unknown Actor') AS actor,
    COALESCE(fm.character_role, 'Unknown Role') AS role,
    COUNT(fm.movie_id) OVER (PARTITION BY fm.production_year) AS movies_count,
    fm.keywords
FROM 
    filtered_movies fm
WHERE 
    fm.depth <= 2
ORDER BY 
    fm.production_year DESC, 
    fm.title;
