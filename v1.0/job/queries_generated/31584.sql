WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year, 
        NULL AS parent_id
    FROM 
        title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id, 
        e.title AS movie_title, 
        e.production_year, 
        mh.movie_id AS parent_id
    FROM 
        title e
    INNER JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),

AggregatedPerformance AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS avg_main_role,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        c.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    ap.cast_count,
    ap.avg_main_role,
    ap.keywords,
    COALESCE(cn.name, 'Unknown Company') AS company_name,
    COALESCE(COUNT(DISTINCT mc.company_id), 0) AS company_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    AggregatedPerformance ap ON mh.movie_id = ap.movie_id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.imdb_id
WHERE 
    mh.production_year >= 2000
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, cn.name
ORDER BY 
    mh.production_year DESC,
    ap.cast_count DESC NULLS LAST
LIMIT 10;
