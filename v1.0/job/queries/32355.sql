WITH RECURSIVE movie_hierarchy AS (
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank
    FROM 
        movie_hierarchy mh
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        ci.movie_id
),
movie_keyword_info AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.level,
    rm.rank,
    COALESCE(cd.total_actors, 0) AS total_actors,
    COALESCE(cd.actor_names, 'No actors listed') AS actor_names,
    COALESCE(mki.keywords, 'No keywords') AS keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_details cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    movie_keyword_info mki ON rm.movie_id = mki.movie_id
WHERE 
    rm.production_year >= 2000
    AND (rm.level = 0 OR (rm.level > 0 AND rm.rank <= 3))
ORDER BY 
    rm.level, rm.rank;