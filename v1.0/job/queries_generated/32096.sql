WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        1 AS level,
        CONCAT(mt.title, ' (', mt.production_year, ')') AS title_with_year
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        CONCAT(mh.title_with_year, ' -> ', mt.title, ' (', mt.production_year, ')')
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.id
)

SELECT 
    m.title,
    m.production_year,
    COALESCE(c.name, 'Unknown Actor') AS actor_name,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    SUM(CASE WHEN ci.nr_order = 1 THEN 1 ELSE 0 END) AS lead_actor_count,
    AVG(mo.production_year) OVER (PARTITION BY mk.keyword) AS average_movie_year_per_keyword,
    CONCAT('KEYWORDS: ', STRING_AGG(mk.keyword, ', ' ORDER BY mk.keyword)) AS keywords_list
FROM 
    movie_hierarchy m
LEFT JOIN 
    complete_cast cc ON m.id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name c ON ci.person_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = m.id AND mi.note IS NULL
WHERE 
    m.production_year BETWEEN 2000 AND 2020
GROUP BY 
    m.title, m.production_year, c.name
ORDER BY 
    m.production_year DESC, keyword_count DESC;
