
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

cast_characters AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),

average_production_year AS (
    SELECT 
        kind_id,
        AVG(production_year) AS avg_year
    FROM 
        aka_title
    GROUP BY 
        kind_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(mk.keyword_list, 'No Keywords') AS keywords,
    COALESCE(cc.total_cast, 0) AS total_cast,
    CASE 
        WHEN mh.production_year < a.avg_year THEN 'Earlier'
        WHEN mh.production_year > a.avg_year THEN 'Later'
        ELSE 'Same Year'
    END AS production_year_comparison
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    cast_characters cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    average_production_year a ON mh.kind_id = a.kind_id
ORDER BY 
    mh.production_year DESC, mh.title ASC
LIMIT 100;
