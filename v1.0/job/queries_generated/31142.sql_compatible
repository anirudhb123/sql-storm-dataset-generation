
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.season_nr,
        mt.episode_nr,
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
        mt.season_nr,
        mt.episode_nr,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
actor_movie_count AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(CAST(mk.keyword_id AS text), ', ') AS keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.season_nr,
        mh.episode_nr,
        COALESCE(ac.movie_count, 0) AS actor_count,
        ks.keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        actor_movie_count ac ON mh.movie_id = ac.actor_id
    LEFT JOIN 
        keyword_summary ks ON mh.movie_id = ks.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.season_nr,
    md.episode_nr,
    md.actor_count,
    md.keywords,
    COALESCE((SELECT AVG(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) 
               FROM cast_info ci WHERE ci.movie_id = md.movie_id), 0) AS average_null_notes
FROM 
    movie_details md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC,
    md.actor_count DESC;
