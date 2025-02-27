WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(SUM(CASE WHEN c.person_role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id
    UNION ALL
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.cast_count + COALESCE(SUM(CASE WHEN c.person_role_id IS NOT NULL THEN 1 ELSE 0 END), 0)
    FROM 
        movie_hierarchy mh
    INNER JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    LEFT JOIN 
        cast_info c ON ml.linked_movie_id = c.movie_id
),
movie_statistics AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.cast_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.cast_count DESC) AS rank_per_year,
        DENSE_RANK() OVER (ORDER BY mh.cast_count DESC) AS overall_rank
    FROM 
        movie_hierarchy mh
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.cast_count,
    ms.rank_per_year,
    ms.overall_rank,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    COALESCE(cn.company_name, 'Independent') AS production_company,
    COUNT(DISTINCT ci.person_id) FILTER (WHERE ci.note IS NOT NULL) AS featured_actors_count
FROM 
    movie_statistics ms
LEFT JOIN 
    movie_keyword mk ON ms.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON ms.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    complete_cast cc ON ms.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
WHERE 
    ms.rank_per_year <= 5
GROUP BY 
    ms.movie_id, 
    ms.title, 
    ms.production_year, 
    ms.cast_count, 
    ms.rank_per_year, 
    ms.overall_rank, 
    mk.keywords, 
    cn.company_name
ORDER BY 
    ms.production_year DESC, 
    ms.overall_rank;
