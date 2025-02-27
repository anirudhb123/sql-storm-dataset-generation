WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    INNER JOIN 
        aka_title m ON m.id = mh.movie_id
    WHERE 
        m.episode_of_id IS NOT NULL
),
movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        c.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(mc.total_cast, 0) AS total_cast,
    COALESCE(mc.cast_names, 'N/A') AS cast_names,
    COALESCE(mk.keywords, 'N/A') AS keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_cast mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2010 OR 
    (mh.level > 1 AND mc.total_cast > 5)
ORDER BY 
    mh.production_year DESC, 
    mh.title ASC;
