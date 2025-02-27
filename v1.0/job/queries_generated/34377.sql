WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.movie_id,
        t.title,
        m.company_id,
        1 AS level
    FROM 
        movie_companies m
    JOIN 
        aka_title t ON m.movie_id = t.movie_id
    WHERE 
        m.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production')
    
    UNION ALL
    
    SELECT 
        mc.movie_id,
        t.title,
        mc.company_id,
        mh.level + 1
    FROM 
        movie_companies mc
    JOIN 
        movie_hierarchy mh ON mc.movie_id = mh.movie_id
    JOIN 
        aka_title t ON mc.movie_id = t.movie_id
    WHERE 
        mh.level < 3 -- limit to 3 levels deep
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY mh.movie_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mh.company_id ORDER BY mh.level DESC, mh.title) AS title_rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
)
SELECT 
    rm.title AS movie_title,
    rm.cast_count,
    CASE 
        WHEN rm.cast_count = 0 THEN 'No Cast'
        WHEN rm.cast_count < 5 THEN 'Few Cast Members'
        WHEN rm.cast_count BETWEEN 5 AND 15 THEN 'Average Cast'
        ELSE 'Large Cast'
    END AS cast_size,
    cn.name AS company_name,
    (SELECT STRING_AGG(DISTINCT kw.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword kw ON mk.keyword_id = kw.id 
     WHERE mk.movie_id = rm.movie_id) AS keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    rm.title_rank = 1 
AND 
    rm.cast_count IS NOT NULL
ORDER BY 
    rm.cast_count DESC, rm.movie_title;
