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
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedTitles AS (
    SELECT 
        mt.*, 
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY mt.production_year) AS title_count
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(SUM(CASE WHEN ci.id IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = mh.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    rt.title_rank,
    rt.title_count,
    CASE 
        WHEN md.cast_count > 0 THEN 'Has Cast' 
        ELSE 'No Cast' 
    END AS cast_status,
    COALESCE(i.info, 'No Info') AS additional_info
FROM 
    MovieDetails md
LEFT JOIN 
    RankedTitles rt ON md.movie_id = rt.id
LEFT JOIN 
    movie_info i ON md.movie_id = i.movie_id AND i.info IS NOT NULL
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, md.cast_count DESC, md.title;
