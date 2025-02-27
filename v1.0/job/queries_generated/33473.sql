WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000
    UNION ALL
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        AKA_TITLE m ON m.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS total_cast, 
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
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
    m.level,
    coalesce(cs.total_cast, 0) AS total_cast,
    coalesce(cs.cast_names, 'No Cast') AS cast_names,
    coalesce(mk.keywords, 'No Keywords') AS keywords,
    CASE
        WHEN m.level > 1 THEN 'Spin-off'
        ELSE 'Original'
    END AS movie_type
FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_summary cs ON m.movie_id = cs.movie_id
LEFT JOIN 
    movie_keywords mk ON m.movie_id = mk.movie_id
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = m.movie_id 
        AND mi.info_type_id IN (
            SELECT id FROM info_type WHERE info = 'Awards'
        )
    )
ORDER BY 
    m.production_year DESC NULLS LAST;
