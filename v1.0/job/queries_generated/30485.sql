WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.parent_movie, 0) AS parent_movie,
        1 AS level
    FROM 
        title m
    WHERE 
        m.parent_movie IS NULL
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.parent_movie, 0) AS parent_movie,
        mh.level + 1 AS level
    FROM 
        title m
    JOIN 
        movie_hierarchy mh ON m.parent_movie = mh.movie_id
),
cast_stats AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS distinct_cast_count,
        STRING_AGG(a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
keyword_stats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_summary AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(cs.distinct_cast_count, 0) AS distinct_cast_count,
        COALESCE(ks.keyword_count, 0) AS keyword_count,
        mh.level
    FROM 
        title m
    LEFT JOIN 
        cast_stats cs ON m.id = cs.movie_id
    LEFT JOIN 
        keyword_stats ks ON m.id = ks.movie_id
    LEFT JOIN 
        movie_hierarchy mh ON m.id = mh.movie_id
)

SELECT 
    ms.movie_id,
    ms.title,
    ms.distinct_cast_count,
    ms.keyword_count,
    CASE 
        WHEN ms.level IS NULL THEN 'Standalone Movie'
        ELSE 'Part of Hierarchy'
    END AS hierarchy_status
FROM 
    movie_summary ms
ORDER BY 
    ms.distinct_cast_count DESC,
    ms.keyword_count DESC 
LIMIT 10;

