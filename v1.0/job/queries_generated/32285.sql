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
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 5 -- Limit the depth of recursion to avoid too many levels
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), FullMovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COUNT(ci.id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id, mk.keywords
), MovieStats AS (
    SELECT 
        f.movie_id,
        f.title,
        f.production_year,
        f.keywords,
        f.cast_count,
        f.company_count,
        ROW_NUMBER() OVER (ORDER BY f.production_year DESC) AS rank,
        RANK() OVER (PARTITION BY f.production_year ORDER BY f.cast_count DESC) AS cast_rank
    FROM 
        FullMovieDetails f
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(fs.keywords, 'N/A') AS movie_keywords,
    COALESCE(fs.cast_count, 0) AS total_cast,
    COALESCE(fs.company_count, 0) AS total_companies,
    mh.level, 
    fs.rank,
    fs.cast_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieStats fs ON mh.movie_id = fs.movie_id
ORDER BY 
    mh.level, mh.production_year DESC;
