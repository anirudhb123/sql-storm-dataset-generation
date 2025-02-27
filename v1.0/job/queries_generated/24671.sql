WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
company_movie_count AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        COUNT(*) AS total_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id, c.name
),
actor_role_counts AS (
    SELECT 
        ci.movie_id,
        ra.role,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type ra ON ci.role_id = ra.id
    GROUP BY 
        ci.movie_id, ra.role
),
movies_with_keywords AS (
    SELECT 
        mt.id AS movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(k.keywords, '{}') AS keywords,
    COALESCE(cc.total_movies, 0) AS total_company_movies,
    ra.role,
    ra.actor_count,
    mh.level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movies_with_keywords k ON mh.movie_id = k.movie_id
LEFT JOIN 
    company_movie_count cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    actor_role_counts ra ON mh.movie_id = ra.movie_id
WHERE 
    mh.production_year > 2000
AND 
    (mm.level = 0 OR ra.actor_count > 2)
ORDER BY 
    mh.production_year DESC, mh.title;

