WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mt.episode_of_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id,
        e.title,
        e.production_year,
        e.episode_of_id,
        mh.level + 1
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.id
),
movie_stats AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN c.nr_order > 0 THEN c.nr_order ELSE NULL END) AS avg_cast_order
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
highest_avg_order AS (
    SELECT 
        movie_id,
        title,
        production_year,
        avg_cast_order
    FROM 
        movie_stats
    WHERE 
        avg_cast_order IS NOT NULL
    ORDER BY 
        avg_cast_order DESC
    LIMIT 5
)
SELECT 
    mh.id AS movie_id,
    mh.title,
    mh.production_year,
    COALESCE(h.avg_cast_order, 0) AS avg_cast_order,
    COALESCE(cast.cid, 0) AS cast_count,
    CASE 
        WHEN mh.level = 1 THEN 'Top Level'
        ELSE 'Sub Level'
    END AS hierarchy_level,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM 
    movie_hierarchy mh
LEFT JOIN 
    highest_avg_order h ON mh.id = h.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         COUNT(DISTINCT person_id) AS cid 
     FROM 
         cast_info 
     GROUP BY 
         movie_id) AS cast ON mh.id = cast.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = mh.id)
GROUP BY 
    mh.id, mh.title, mh.production_year, h.avg_cast_order, mh.level, cast.cid
ORDER BY 
    mh.production_year DESC, avg_cast_order DESC;

