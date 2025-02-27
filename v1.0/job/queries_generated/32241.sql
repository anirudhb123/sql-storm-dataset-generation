WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.id IS NOT NULL 
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_details AS (
    SELECT 
        ca.movie_id,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names,
        COUNT(ca.id) AS total_cast
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        ca.movie_id
),
title_info AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(NULLIF(mk.keyword, ''), 'No Keywords') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year > 1990
),
performance_benchmark AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cd.actor_names,
        cd.total_cast,
        ti.keywords,
        ti.title_rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_details cd ON mh.movie_id = cd.movie_id
    LEFT JOIN 
        title_info ti ON mh.movie_id = ti.movie_id
)
SELECT 
    pb.title,
    pb.production_year,
    pb.total_cast,
    pb.keywords,
    CASE 
        WHEN pb.title_rank <= 10 THEN 'Top 10 of Year'
        WHEN pb.total_cast > 50 THEN 'Large Cast'
        ELSE 'Misc'
    END AS classification
FROM 
    performance_benchmark pb
WHERE 
    pb.keywords IS NOT NULL
ORDER BY 
    pb.production_year DESC, 
    pb.total_cast DESC;
