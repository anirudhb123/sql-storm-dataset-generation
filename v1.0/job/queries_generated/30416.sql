WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level,
        mt.id AS root_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        linked_mt.title,
        linked_mt.production_year,
        mh.level + 1,
        mh.root_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title linked_mt ON ml.linked_movie_id = linked_mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(mi.info, ', ') AS movie_info
    FROM 
        movie_info mi
    JOIN 
        aka_title m ON mi.movie_id = m.id
    GROUP BY 
        m.movie_id
),

PersonRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS unique_actors,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors_list
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),

RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mp.unique_actors,
        mp.actors_list,
        mi.movie_info,
        ROW_NUMBER() OVER (PARTITION BY mh.root_movie_id ORDER BY mh.level DESC) AS ranking_level
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        PersonRoles mp ON mh.movie_id = mp.movie_id
    LEFT JOIN 
        MovieInfo mi ON mh.movie_id = mi.movie_id
)

SELECT 
    rm.movie_title,
    rm.production_year,
    rm.unique_actors,
    rm.actors_list,
    rm.movie_info,
    CASE 
        WHEN rm.ranking_level = 1 THEN 'Root Level'
        WHEN rm.ranking_level <= 3 THEN 'Child Level'
        ELSE 'Distant Level'
    END AS hierarchy_level
FROM 
    RankedMovies rm
WHERE 
    rm.unique_actors > 5 OR rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.movie_title;
