WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rank
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND mt.production_year IS NOT NULL
), 
full_cast_info AS (
    SELECT 
        ci.movie_id,
        COALESCE(ak.name, 'Unknown') AS actor_name,
        cc.kind AS role
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        comp_cast_type cc ON ci.role_id = cc.id
), 
movie_info_data AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(mi.info, ', ') AS info_details
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
), 
cast_aggregate AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT actor_name) AS actor_count,
        STRING_AGG(DISTINCT actor_name, ', ') AS all_actors
    FROM 
        full_cast_info
    GROUP BY 
        movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ca.actor_count, 0) AS total_actors,
    COALESCE(ca.all_actors, 'No actors') AS actors_list,
    mi.info_details
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_aggregate ca ON rm.movie_id = ca.movie_id
LEFT JOIN 
    movie_info_data mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 10 -- Top 10 movies by title within each production year
AND 
    (rm.production_year < 2000 OR mi.info_details IS NOT NULL) -- Movies pre-2000 or with additional info
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;

-- Note: This query selects the top 10 movies for each year based on their title while providing
-- actor counts and additional movie information. It incorporates various SQL features including
-- CTEs, string aggregation, COALESCE for NULL handling, and conditional filtering.
