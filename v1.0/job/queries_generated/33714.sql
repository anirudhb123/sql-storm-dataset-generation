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
        ml.linked_movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
movie_performances AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COUNT(cc.person_id) AS cast_count,
        AVG(mi.info::numeric) AS avg_budget,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
    LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mh.movie_id, 
        mh.title 
)
SELECT 
    m.*,
    COALESCE(cast_info.name, 'Unknown') AS main_actor,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.cast_count DESC) AS rank_within_year,
    (SELECT COUNT(*) FROM aka_title WHERE production_year = m.production_year) AS total_movies_year,
    CASE 
        WHEN m.avg_budget IS NULL THEN 'Budget Unknown'
        WHEN m.avg_budget < 500000 THEN 'Low Budget'
        WHEN m.avg_budget BETWEEN 500000 AND 5000000 THEN 'Medium Budget'
        ELSE 'High Budget'
    END AS budget_category
FROM 
    movie_performances m
LEFT JOIN (
    SELECT 
        cc.movie_id,
        ak.name 
    FROM 
        cast_info cc 
    JOIN aka_name ak ON cc.person_id = ak.person_id
    WHERE 
        cc.nr_order = 1 
) AS cast_info ON m.movie_id = cast_info.movie_id
WHERE 
    m.cast_count > 0
ORDER BY 
    m.cast_count DESC, 
    m.title;
