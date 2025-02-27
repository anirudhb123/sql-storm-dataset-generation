WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(NULL AS VARCHAR) AS parent_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mt.title AS parent_title,
        mh.level + 1 AS level
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
)

SELECT 
    ma.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT ci.person_id) OVER(PARTITION BY m.id) AS actor_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(CASE WHEN mi.info_type_id = 4 THEN 1 ELSE 0 END) AS has_plot_info,
    CASE 
        WHEN COUNT(DISTINCT ci.id) >= 5 THEN 'Ensemble Cast'
        WHEN COUNT(DISTINCT ci.id) BETWEEN 3 AND 4 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
JOIN 
    aka_name ma ON ci.person_id = ma.person_id
JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id AND mi.info_type_id IN (1, 4)
JOIN 
    aka_title m ON m.id = mh.movie_id
GROUP BY 
    ma.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY 
    m.production_year DESC, actor_count DESC;
