WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(NULL AS INTEGER) AS season_parent_id,
        CAST(NULL AS INTEGER) AS episode_parent_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        CASE 
            WHEN et.season_nr IS NOT NULL THEN et.id
            ELSE mh.season_parent_id
        END AS season_parent_id,
        CASE 
            WHEN et.episode_nr IS NOT NULL THEN et.id
            ELSE mh.episode_parent_id
        END AS episode_parent_id,
        mh.level + 1
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
    WHERE 
        et.kind_id = (SELECT id FROM kind_type WHERE kind IN ('episode', 'season'))
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.season_parent_id ORDER BY mh.production_year DESC) AS rank
    FROM 
        movie_hierarchy mh
    WHERE 
        mh.level = 0 OR mh.season_parent_id IS NOT NULL
),
top_ranked_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank = 1
),
cast_data AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
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
    tm.title,
    tm.production_year,
    cd.actor_count,
    ks.keywords
FROM 
    top_ranked_movies tm
LEFT JOIN 
    cast_data cd ON tm.movie_id = cd.movie_id
LEFT JOIN 
    keyword_summary ks ON tm.movie_id = ks.movie_id
WHERE 
    (cd.actor_count IS NOT NULL AND cd.actor_count > 5)
    OR 
    (tm.production_year IS NOT NULL AND tm.production_year > 2000)
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC
FETCH FIRST 10 ROWS ONLY;