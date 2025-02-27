WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
  
    UNION ALL
  
    SELECT 
        mm.id AS movie_id,
        mm.title,
        mm.production_year,
        mh.level + 1
    FROM 
        aka_title mm
    JOIN 
        movie_link ml ON ml.linked_movie_id = mm.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),

AggregatedGenres AS (
    SELECT 
        at.id AS movie_id, 
        COUNT(DISTINCT ak.keyword) AS genre_count 
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = at.id
    LEFT JOIN 
        keyword ak ON ak.id = mk.keyword_id
    GROUP BY 
        at.id
),

MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ag.genre_count, 0) AS genre_count,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS all_cast_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = mh.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    LEFT JOIN 
        AggregatedGenres ag ON ag.movie_id = mh.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, ag.genre_count
    ORDER BY 
        mh.production_year DESC, genre_count DESC
)

SELECT 
    ms.title,
    ms.production_year,
    ms.genre_count,
    ms.cast_count,
    ms.all_cast_names,
    CASE 
        WHEN ms.genre_count > 5 THEN 'High'
        WHEN ms.genre_count BETWEEN 1 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS genre_diversity,
    COALESCE(NULLIF(ms.all_cast_names, ''), 'No cast available') AS cast_names_output
FROM 
    MovieStats ms
WHERE 
    ms.cast_count > 2
  AND 
    ms.production_year BETWEEN 2000 AND 2020
ORDER BY 
    genre_diversity DESC, ms.cast_count DESC;
