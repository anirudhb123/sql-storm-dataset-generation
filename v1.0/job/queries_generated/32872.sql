WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.id IS NOT NULL

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
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
AggregatedCast AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS total_cast,
        STRING_AGG(ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ac.total_cast, 0) AS total_cast,
        COALESCE(ac.cast_names, 'No Cast') AS cast_names,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        AggregatedCast ac ON mh.movie_id = ac.movie_id
    LEFT JOIN 
        MovieKeywords mk ON mh.movie_id = mk.movie_id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.total_cast,
    ms.cast_names,
    ms.keywords,
    RANK() OVER (ORDER BY ms.production_year DESC, ms.total_cast DESC) AS rank_by_year_and_cast
FROM 
    MovieStats ms
WHERE 
    ms.production_year >= 2000
ORDER BY 
    ms.production_year DESC, 
    ms.total_cast DESC;

