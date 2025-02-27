WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title m ON mh.movie_id = m.episode_of_id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(c.name, 'No Cast') AS cast_name,
    COUNT(c.id) OVER (PARTITION BY m.id) AS total_cast,
    COALESCE(info.info, 'No Info') AS additional_info,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.nr_order) AS cast_order
FROM 
    movie_hierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND (c.note IS NULL OR c.note <> 'Cameo')
GROUP BY 
    m.movie_id, m.title, m.production_year, c.name, info.info
ORDER BY 
    m.production_year DESC,
    total_cast DESC,
    movie_title ASC;
