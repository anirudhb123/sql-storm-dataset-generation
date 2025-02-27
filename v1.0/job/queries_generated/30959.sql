WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year >= 2000
),
cast_summary AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cs.total_cast,
        cs.cast_names
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_summary cs ON mh.movie_id = cs.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.total_cast, 0) AS total_cast,
    COALESCE(md.cast_names, 'No cast listed') AS cast_names,
    (SELECT COUNT(*) 
     FROM movie_info mi
     WHERE mi.movie_id = md.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')) AS summary_count,
    ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.title) AS rank
FROM 
    movie_details md
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC, total_cast DESC
LIMIT 50;
