WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        0 AS level 
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        mt.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year >= 2000
),
CastStats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS unique_cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        cs.unique_cast_count,
        cs.cast_names,
        mk.keywords 
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastStats cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        MovieKeywords mk ON mh.movie_id = mk.movie_id
)
SELECT 
    dmi.movie_id,
    dmi.movie_title,
    COALESCE(dmi.unique_cast_count, 0) AS unique_cast_count,
    COALESCE(dmi.cast_names, 'No Cast') AS cast_names,
    COALESCE(dmi.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN dmi.unique_cast_count > 5 THEN 'Popular'
        WHEN dmi.unique_cast_count IS NULL THEN 'No Cast'
        ELSE 'Niche'
    END AS movie_category
FROM 
    DetailedMovieInfo dmi
ORDER BY 
    dmi.movie_title;
