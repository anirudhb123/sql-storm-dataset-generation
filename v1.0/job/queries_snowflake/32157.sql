
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        h.level + 1
    FROM 
        MovieHierarchy h
    JOIN 
        movie_link ml ON h.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        h.level < 5 
),
AggregatedCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        CASE 
            WHEN m.production_year IS NULL THEN 'Unknown Year'
            ELSE CAST(m.production_year AS STRING)
        END AS production_year,
        COALESCE(mc.cast_count, 0) AS total_cast,
        COALESCE(mc.actor_names, 'No Cast') AS cast_names
    FROM 
        aka_title m
    LEFT JOIN 
        AggregatedCast mc ON m.id = mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    CASE 
        WHEN mh.level = 1 THEN 'Original'
        WHEN mh.level > 1 THEN 'Sequel/Related'
        ELSE 'Unknown'
    END AS relation_level,
    mi.total_cast,
    mi.cast_names,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.production_year DESC) AS rank_within_level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
GROUP BY 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mi.total_cast,
    mi.cast_names
ORDER BY 
    mh.production_year DESC, 
    mh.level,
    rank_within_level;
