WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.depth + 1 AS depth
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id, 
        mh.movie_title,
        ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY a.production_year DESC) as rank,
        a.production_year
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title a ON mh.movie_id = a.movie_id
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 5
),
cast_data AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(an.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
movie_info_data AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT mi.info) AS movie_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
)
SELECT 
    fm.movie_id,
    fm.movie_title,
    fm.production_year,
    cd.actor_names,
    MID.movie_info
FROM 
    filtered_movies fm
LEFT JOIN 
    cast_data cd ON fm.movie_id = cd.movie_id
LEFT JOIN 
    movie_info_data MID ON fm.movie_id = MID.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.movie_title;
