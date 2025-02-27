WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),

MovieStats AS (
    SELECT 
        m.id,
        m.title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.id, m.title
),

InfoCTE AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, ', ') AS all_info
    FROM 
        movie_info mi
    INNER JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    COALESCE(ms.actor_count, 0) AS actor_count,
    COALESCE(ms.avg_order, 0) AS avg_order,
    COALESCE(ic.all_info, 'No additional info') AS additional_info,
    mh.level AS hierarchy_level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieStats ms ON mh.movie_id = ms.id
LEFT JOIN 
    InfoCTE ic ON mh.movie_id = ic.movie_id
WHERE 
    mh.level > 0 
ORDER BY 
    mh.production_year DESC, mh.title;