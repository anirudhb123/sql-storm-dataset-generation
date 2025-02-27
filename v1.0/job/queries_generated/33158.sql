WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
),
movie_stats AS (
    SELECT 
        m.movie_id,
        m.title,
        COUNT(c.id) AS cast_count,
        AVG(COALESCE(pi.info::integer, 0)) AS avg_actor_age
    FROM 
        movie_hierarchy m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'age')
    GROUP BY 
        m.movie_id, m.title
),
keywords_summary AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.cast_count,
    ms.avg_actor_age,
    COALESCE(ks.keywords, 'No keywords') AS keywords
FROM 
    movie_stats ms
LEFT JOIN 
    keywords_summary ks ON ms.movie_id = ks.movie_id
WHERE 
    ms.cast_count > 5
ORDER BY 
    ms.cast_count DESC, ms.avg_actor_age ASC
LIMIT 10;

