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
        m.title,
        m.production_year,
        mh.level + 1 
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
, MovieCast AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        complete_cast mc
    JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        mc.movie_id
)
, MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT i.info ORDER BY i.info_type_id) AS movie_infos
    FROM 
        movie_info mi
    JOIN 
        info_type i ON mi.info_type_id = i.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mc.cast_count, 0) AS cast_count,
    COALESCE(mc.actor_names, 'No Cast') AS actor_names,
    COALESCE(mi.movie_infos, 'No Info') AS movie_infos,
    RANK() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank_within_level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieCast mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.level <= 2
ORDER BY 
    mh.level, mh.production_year DESC;
