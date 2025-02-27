WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(NULLIF(mk.keyword, ''), 'No Keyword') AS keyword,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year > 2000
    UNION ALL
    SELECT 
        mh.movie_id,
        m.title,
        m.production_year,
        COALESCE(NULLIF(mk.keyword, ''), 'No Keyword') AS keyword,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        mh.level < 3
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.keyword,
        COALESCE(cd.num_cast, 0) AS num_cast,
        cd.cast_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN CastDetails cd ON mh.movie_id = cd.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.keyword,
    ms.num_cast,
    ROW_NUMBER() OVER (PARTITION BY ms.production_year ORDER BY ms.num_cast DESC) AS rank_within_year,
    CASE 
        WHEN ms.num_cast > 0 THEN 'Movie has cast'
        ELSE 'No cast available' 
    END AS cast_availability
FROM 
    MovieStats ms
WHERE 
    ms.num_cast > 5 OR ms.keyword LIKE '%Action%'
ORDER BY 
    ms.production_year DESC, ms.num_cast DESC;
