WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title AS movie_title,
        et.production_year,
        mh.level + 1
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),
cast_aggregates AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
        COUNT(DISTINCT ci.person_id) AS total_actors
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        ca.actor_names,
        ca.total_actors,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_aggregates ca ON mh.movie_id = ca.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id 
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.production_year, ca.actor_names, ca.total_actors
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_names,
    md.total_actors,
    md.keyword_count,
    COALESCE(mo.company_name, 'Unknown') AS production_company,
    RANK() OVER (PARTITION BY md.production_year ORDER BY md.total_actors DESC) AS actor_rank
FROM 
    movie_details md
LEFT JOIN 
    (SELECT 
         mc.movie_id, 
         cn.name AS company_name
     FROM 
         movie_companies mc
     JOIN 
         company_name cn ON mc.company_id = cn.id
     WHERE 
         cn.country_code = 'USA') mo ON md.movie_id = mo.movie_id
WHERE 
    md.keyword_count > 1 
ORDER BY 
    md.production_year DESC, md.total_actors DESC;
