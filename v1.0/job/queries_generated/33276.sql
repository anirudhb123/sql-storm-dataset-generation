WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.season_nr, 0) AS season_nr,
        COALESCE(mt.episode_nr, 0) AS episode_nr,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    UNION ALL
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.season_nr, 0) AS season_nr,
        COALESCE(mt.episode_nr, 0) AS episode_nr,
        mh.level + 1 AS level
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_details AS (
    SELECT 
        ci.person_id,
        cn.name,
        ct.kind AS role,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        name cn ON ci.person_id = cn.imdb_id
    JOIN 
        role_type ct ON ci.role_id = ct.id
    GROUP BY 
        ci.person_id, cn.name, ct.kind
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.season_nr,
        mh.episode_nr,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC, mh.title) AS rank
    FROM 
        movie_hierarchy mh
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.name,
    cd.role,
    cd.movie_count,
    rm.season_nr,
    rm.episode_nr
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_details cd ON rm.movie_id = cd.movie_count
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC,
    rm.title ASC
LIMIT 100;
