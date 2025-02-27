WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        COALESCE(mt.season_nr, 0) AS season_number,
        COALESCE(mt.episode_nr, 0) AS episode_number,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id, 
        m.title, 
        m.production_year,
        COALESCE(m.season_nr, 0),
        COALESCE(m.episode_nr, 0),
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
, movie_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    mh.movie_id, 
    mh.title, 
    mh.production_year, 
    mh.season_number, 
    mh.episode_number, 
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COUNT(cc.person_id) AS cast_count,
    AVG(CASE 
        WHEN cc.nr_order IS NULL THEN 0 
        ELSE cc.nr_order 
    END) AS avg_order,
    COUNT(DISTINCT CASE 
        WHEN cc.note IS NOT NULL THEN cc.person_id 
        ELSE NULL 
    END) AS distinct_actors_with_note
FROM
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id    
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, 
    mh.season_number, mh.episode_number, mk.keywords
HAVING 
    COUNT(cc.person_id) > 0 
    AND AVG(COALESCE(cc.nr_order, 0)) < 10
ORDER BY 
    mh.production_year DESC,
    mh.depth ASC,
    mh.title;
