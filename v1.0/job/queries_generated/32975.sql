WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title AS m
    INNER JOIN 
        movie_link AS ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5 -- limiting levels for recursion
),
cast_statistics AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actors
    FROM 
        cast_info AS ci
    INNER JOIN 
        aka_name AS an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
keyword_statistics AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword AS mk
    GROUP BY 
        mk.movie_id
),
info_summary AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Genre' THEN mi.info END) AS genre,
        MAX(CASE WHEN it.info = 'Rating' THEN mi.info END) AS rating
    FROM 
        movie_info AS mi
    JOIN 
        info_type AS it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    cs.actor_count,
    cs.actors,
    ks.keyword_count,
    is.genre,
    is.rating,
    COALESCE(NULLIF(is.rating, ''), 'Not Rated') AS final_rating
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    cast_statistics AS cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    keyword_statistics AS ks ON mh.movie_id = ks.movie_id
LEFT JOIN 
    info_summary AS is ON mh.movie_id = is.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mh.production_year DESC, actor_count DESC
LIMIT 100;
