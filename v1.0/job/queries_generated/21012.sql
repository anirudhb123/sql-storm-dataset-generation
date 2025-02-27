WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        NULL::text AS parent_movie_title,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        title m ON t.movie_id = m.id
    WHERE 
        m.production_year > 2000
    UNION ALL
    SELECT 
        mm.id,
        m.title,
        mm.production_year,
        mh.title AS parent_movie_title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        aka_title mt ON m.id = mt.movie_id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    WHERE 
        mh.level < 3
)
SELECT 
    CASE 
        WHEN mh.level IS NOT NULL THEN mh.title 
        ELSE 'N/A' 
    END AS linked_movie_title,
    COALESCE(SUM(CASE WHEN cc.person_role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_roles,
    COUNT(DISTINCT mk.keyword) AS distinct_keywords,
    AVG(p.perf_rating) AS average_performance_metric,
    STRING_AGG(DISTINCT COALESCE(a.name, 'Unknown Actor'), ', ') AS actors_in_linked_movie
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    aka_name a ON cc.person_id = a.person_id
LEFT JOIN 
    (SELECT 
        person_id, 
        AVG(performance_score) AS perf_rating 
     FROM 
        performance_metrics 
     WHERE 
        score_date >= CURRENT_DATE - INTERVAL '1 year' 
     GROUP BY 
        person_id) p ON a.person_id = p.person_id
GROUP BY 
    mh.movie_id, mh.level, mh.parent_movie_title
ORDER BY 
    mh.level DESC, 
    total_roles DESC NULLS LAST;

-- Potentially create a hypothetical `performance_metrics` table for benchmarking purposes
-- assuming it contains columns person_id and performance_score.
