WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_info_aggregated AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(md.info, 'No info available') AS additional_info,
        COALESCE(cd.cast_count, 0) AS cast_count,
        COALESCE(cd.cast_names, 'No cast listed') AS cast_names
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info_idx md ON mt.id = md.movie_id AND md.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
    LEFT JOIN 
        cast_details cd ON mt.id = cd.movie_id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    ma.additional_info,
    ma.cast_count,
    ma.cast_names,
    ROW_NUMBER() OVER(PARTITION BY mh.production_year ORDER BY ma.cast_count DESC) AS rank_per_year,
    RANK() OVER(ORDER BY mh.level DESC) AS rank_overall
FROM 
    movie_hierarchy mh
JOIN 
    movie_info_aggregated ma ON mh.movie_id = ma.movie_id
WHERE 
    ma.cast_count > 2 AND 
    mh.level <= 3
ORDER BY 
    mh.production_year DESC, rank_per_year;

This SQL query includes several advanced constructs:
- A recursive Common Table Expression (CTE) to build a movie hierarchy based on links between movies.
- Another CTE to aggregate cast information.
- A main query that joins these CTEs, performs string aggregation, and uses window functions for ranking.
- It features various JOIN types (inner and left joins) and filtering based on complex predicates.
- It handles NULL cases with `COALESCE` and performs ordering based on rank metrics.
