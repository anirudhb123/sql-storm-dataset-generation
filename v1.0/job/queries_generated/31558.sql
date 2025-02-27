WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
actor_stats AS (
    SELECT 
        a.name,
        COUNT(DISTINCT c.movie_id) AS movies_count,
        AVG(CASE WHEN (j.status_id IS NOT NULL) THEN 1 ELSE 0 END) * 100 AS success_rate
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        complete_cast j ON c.movie_id = j.movie_id AND c.person_id = j.subject_id
    GROUP BY 
        a.name
),
movie_keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_result AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        a.movies_count,
        COALESCE(a.success_rate, 0) AS success_rate,
        CASE 
            WHEN a.success_rate > 75 THEN 'Successful Actor'
            ELSE 'Needs Improvement'
        END AS actor_performance,
        mk.keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        actor_stats a ON mh.movie_id = a.movies_count
    LEFT JOIN 
        movie_keyword_summary mk ON mh.movie_id = mk.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    movies_count,
    success_rate,
    actor_performance,
    keywords
FROM 
    final_result
WHERE 
    production_year = (
        SELECT MAX(production_year) FROM final_result
    )
ORDER BY 
    success_rate DESC, 
    title;
