
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth,
        m.id AS root_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1,
        mh.root_id
    FROM 
        aka_title m
    INNER JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
cast_aggregates AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
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
        COALESCE(ca.total_actors, 0) AS total_actors,
        ca.actor_names,
        ROW_NUMBER() OVER (PARTITION BY mh.root_id ORDER BY mh.production_year DESC) AS rn
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_aggregates ca ON mh.movie_id = ca.movie_id
),
extended_movie_info AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_actors,
        md.actor_names,
        (SELECT COUNT(DISTINCT mc.company_id) 
         FROM movie_companies mc 
         WHERE mc.movie_id = md.movie_id) AS total_companies,
        (SELECT COUNT(DISTINCT mw.keyword_id) 
         FROM movie_keyword mw 
         WHERE mw.movie_id = md.movie_id) AS total_keywords
    FROM 
        movie_details md
)
SELECT 
    emi.movie_id,
    emi.title,
    emi.production_year,
    emi.total_actors,
    emi.actor_names,
    emi.total_companies,
    emi.total_keywords
FROM 
    extended_movie_info emi
WHERE 
    emi.total_actors > 5 
    AND emi.total_companies > 0
ORDER BY 
    emi.production_year DESC, emi.total_actors DESC;
