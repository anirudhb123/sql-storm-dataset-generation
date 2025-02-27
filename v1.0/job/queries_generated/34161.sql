WITH RECURSIVE movie_hierarchy AS (
    -- Base case: select the root movies
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    -- Recursive case: join related episodes
    SELECT 
        et.id AS movie_id,
        et.title,
        mh.level + 1
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),
ranked_movie_cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
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
    COALESCE(rmc.actor_name, 'Unknown Actor') AS actor_name,
    rmc.actor_rank,
    mk.keywords,
    mt.production_year,
    COUNT(cm.company_id) AS company_count,
    SUM(CASE WHEN mt.production_year < 2000 THEN 1 ELSE 0 END) AS pre_2000_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    ranked_movie_cast rmc ON mh.movie_id = rmc.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    mh.movie_id, mh.title, rmc.actor_name, rmc.actor_rank, mk.keywords, mt.production_year
ORDER BY 
    mh.title, actor_rank
LIMIT 100;
