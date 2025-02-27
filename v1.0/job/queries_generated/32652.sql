WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000 
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        lm.linked_movie_id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mh.level + 1
    FROM 
        movie_link lm
    JOIN 
        aka_title mt ON lm.linked_movie_id = mt.movie_id
    JOIN 
        movie_hierarchy mh ON lm.movie_id = mh.movie_id
    WHERE 
        mt.production_year IS NOT NULL
),
ranked_cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    rk.actor_name,
    rk.actor_rank,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    ranked_cast rk ON mh.movie_id = rk.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year = (
        SELECT MAX(mh2.production_year) 
        FROM movie_hierarchy mh2
        WHERE mh2.movie_id = mh.movie_id
    )
ORDER BY 
    mh.production_year DESC, 
    rk.actor_rank
LIMIT 50;
