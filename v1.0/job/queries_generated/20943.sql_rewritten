WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        CAST(NULL AS INTEGER) AS parent_movie_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL
    
    UNION ALL 
    
    SELECT 
        c.movie_id,
        t.title,
        t.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM 
        complete_cast c
    JOIN movie_hierarchy mh ON c.movie_id = mh.movie_id
    JOIN aka_title t ON c.movie_id = t.id
    WHERE 
        t.episode_of_id IS NOT NULL
)

SELECT 
    mh.title AS episode_title,
    mh.production_year,
    mh.level,
    ARRAY_AGG(DISTINCT ak.name) AS actor_names,
    CASE 
        WHEN COUNT(DISTINCT ak.name) = 0 THEN 'No Actors'
        ELSE 'Actors Found'
    END AS actor_status,
    COALESCE(mt.info, 'Unknown genre') AS genre,
    COALESCE(MAX(mi.info), 'No Info') AS additional_info
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mt ON mh.movie_id = mt.movie_id AND mt.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Genre')
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id != (
        SELECT id FROM info_type WHERE info = 'Genre')
WHERE 
    mh.level <= 5 
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, mt.info
ORDER BY 
    mh.production_year DESC, mh.level, actor_status
LIMIT 100;