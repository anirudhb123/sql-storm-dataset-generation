WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023 

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastStats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
ProductionStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    mh.level,
    cs.total_cast,
    cs.cast_names,
    ps.total_companies,
    ps.company_names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastStats cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    ProductionStats ps ON mh.movie_id = ps.movie_id
WHERE 
    (mh.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series')))
    AND (cs.total_cast IS NOT NULL OR ps.total_companies IS NOT NULL)
ORDER BY 
    mh.production_year DESC, mh.level, mh.title;
