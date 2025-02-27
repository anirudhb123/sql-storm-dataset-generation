WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year, 
        0 AS level
    FROM aka_title mt
    WHERE mt.kind_id = 1  -- Assume 1 is for movies

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

MostFrequentActors AS (
    SELECT 
        ci.person_id, 
        COUNT(ci.movie_id) AS movie_count
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY ci.person_id
    ORDER BY movie_count DESC
    LIMIT 10
),

MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword), 'No keywords') AS keywords,
        AVG(mi.info IS NOT NULL) AS has_information
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id AND mi.info_type_id IN (1, 2)  -- Assume 1 and 2 are for important info types
    GROUP BY m.id
)

SELECT 
    mh.movie_id,
    mh.title AS movie_title, 
    mh.production_year, 
    fa.person_id AS top_actor_id, 
    an.name AS top_actor_name, 
    mi.keywords,
    mi.has_information,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY mi.has_information DESC) AS info_rank,
    CASE 
        WHEN mi.has_information = 1 THEN 'Has Information'
        ELSE 'Missing Information'
    END AS information_status
FROM MovieHierarchy mh
LEFT JOIN MostFrequentActors fa ON mh.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = fa.person_id)
LEFT JOIN aka_name an ON fa.person_id = an.person_id
LEFT JOIN MovieInfo mi ON mh.movie_id = mi.movie_id 
ORDER BY mh.production_year DESC, info_rank;
