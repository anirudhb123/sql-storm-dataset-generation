WITH RECURSIVE movie_chain AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m2.id,
        m2.title,
        mc.depth + 1
    FROM 
        movie_chain mc
    JOIN 
        movie_link ml ON mc.movie_id = ml.movie_id
    JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    WHERE 
        mc.depth < 3
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
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
    m.movie_id,
    m.movie_title,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.cast_names, 'No Cast') AS cast_names,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    mc.depth AS link_depth
FROM 
    movie_chain m
LEFT JOIN 
    cast_summary cs ON m.movie_id = cs.movie_id
LEFT JOIN 
    movie_keywords mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    aka_title at ON m.movie_id = at.id
WHERE 
    (at.production_year IS NOT NULL AND at.production_year > 2010)
    AND (mk.keywords IS NOT NULL OR cs.total_cast > 0)
ORDER BY 
    link_depth DESC, 
    total_cast DESC;
