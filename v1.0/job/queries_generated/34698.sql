WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        ARRAY_AGG(DISTINCT CONCAT(a.name, ' (', c.kind, ')')) AS cast,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year, mk.keyword
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.keyword,
        mh.cast,
        mh.actor_rank
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id 
    WHERE 
        mh.actor_rank < 5
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.keyword,
    mh.cast,
    mh.actor_rank,
    COUNT(DISTINCT ml.linked_movie_id) AS linked_movies,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_link ml ON mh.movie_id = ml.movie_id
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.keyword, mh.cast, mh.actor_rank
HAVING 
    COUNT(DISTINCT ml.linked_movie_id) > 0 AND 
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) >= 1
ORDER BY 
    mh.production_year DESC, mh.keyword;
