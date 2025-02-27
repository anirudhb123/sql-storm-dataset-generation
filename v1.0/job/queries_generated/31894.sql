WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        mv.linked_movie_id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link mv
    JOIN 
        title m ON mv.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mv.movie_id = mh.movie_id
    WHERE 
        m.production_year IS NOT NULL
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    ARRAY_AGG(DISTINCT CONCAT(md.info, ' (', it.info, ')')) AS info,
    MAX(CASE WHEN rn.rn = 1 THEN md.info ELSE NULL END) AS first_movie_info,
    AVG(mh.depth) AS avg_depth_of_links
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_info md ON c.movie_id = md.movie_id
LEFT JOIN 
    info_type it ON md.info_type_id = it.id
LEFT JOIN 
    (SELECT 
        movie_id, 
        ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY id) AS rn 
    FROM 
        movie_info 
    WHERE 
        info_type_id = (SELECT id FROM info_type WHERE info = 'release_date') 
    ) rn ON rn.movie_id = c.movie_id
WHERE 
    a.name IS NOT NULL 
GROUP BY 
    a.name
ORDER BY 
    total_movies DESC;
