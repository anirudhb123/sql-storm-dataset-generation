
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year = 2023
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
    WHERE 
        m.production_year = 2023
),
cast_role_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT r.role, ', ') WITHIN GROUP (ORDER BY r.role) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movies_with_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(cas.actor_count, 0) AS actor_count,
        COALESCE(kw.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN m.production_year < 2000 THEN 'Classic'
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era,
        mh.level AS hierarchy_level
    FROM 
        aka_title m
    LEFT JOIN 
        cast_role_summary cas ON m.id = cas.movie_id
    LEFT JOIN 
        movie_keywords kw ON m.id = kw.movie_id
    LEFT JOIN 
        movie_hierarchy mh ON m.id = mh.movie_id
)
SELECT 
    m.movie_id,
    m.movie_title,
    m.actor_count,
    m.keywords,
    m.era,
    m.hierarchy_level
FROM 
    movies_with_details m
WHERE 
    m.actor_count >= 3
ORDER BY 
    m.hierarchy_level DESC, 
    m.movie_title ASC
LIMIT 10;
