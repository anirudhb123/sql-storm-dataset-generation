WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.season_nr, 0) AS season_number,
        COALESCE(mt.episode_nr, 0) AS episode_number,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 

    UNION ALL 

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        COALESCE(at.season_nr, 0),
        COALESCE(at.episode_nr, 0),
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
aggregated_cast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.season_number,
        mh.episode_number,
        COALESCE(ac.cast_count, 0) AS total_cast,
        ac.actor_names
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        aggregated_cast ac ON mh.movie_id = ac.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.season_number,
    md.episode_number,
    md.total_cast,
    (CASE 
        WHEN md.total_cast > 0 THEN 'Movie has cast' 
        ELSE 'No cast information available' 
     END) AS cast_info_status
FROM 
    movie_details md
WHERE 
    md.production_year >= 2000
    AND (md.episode_number > 0 OR md.season_number > 0 OR md.total_cast > 0)
ORDER BY 
    md.production_year DESC, md.total_cast DESC
LIMIT 100;
