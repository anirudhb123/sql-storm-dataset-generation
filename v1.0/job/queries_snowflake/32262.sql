
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.episode_of_id IS NULL 
    
    UNION ALL 
    
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        aka_title AS at
    JOIN 
        movie_hierarchy AS mh ON at.episode_of_id = mh.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(AVG(ci.nr_order), 0) AS avg_cast_order,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_hierarchy AS mh
    LEFT JOIN 
        complete_cast AS cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_companies AS mc ON mh.movie_id = mc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
keyword_stats AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        aka_title AS mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.avg_cast_order,
    md.company_count,
    COALESCE(ks.keywords, 'No keywords') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.avg_cast_order DESC) AS rank
FROM 
    movie_details AS md
LEFT JOIN 
    keyword_stats AS ks ON md.movie_id = ks.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.avg_cast_order DESC;
