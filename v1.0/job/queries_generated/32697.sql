WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

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
person_roles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
),
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(pr.actor_name, 'Unknown') AS actor_name,
    COALESCE(pr.role, 'N/A') AS role,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    mh.depth,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.production_year DESC, mh.title) AS year_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    person_roles pr ON mh.movie_id = pr.movie_id
LEFT JOIN 
    movies_with_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
    AND (pr.role IS NOT NULL OR mh.depth = 1)
ORDER BY 
    mh.production_year DESC, 
    mh.title ASC;
