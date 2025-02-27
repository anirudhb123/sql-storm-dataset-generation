WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id 
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.depth < 3  -- Limit hierarchy depth to 3
),

MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        c.name AS company_name,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = a.id) AS keyword_count,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        a.production_year IS NOT NULL
),

RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.company_name,
        md.keyword_count,
        md.cast_count,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC, md.keyword_count ASC) AS rank
    FROM 
        MovieDetails md
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    rm.rank,
    CASE 
        WHEN rm.company_name IS NULL THEN 'Independent'
        ELSE rm.company_name 
    END AS final_company,
    COALESCE(rm.keyword_count, 0) AS total_keywords,
    COALESCE(rm.cast_count, 0) AS total_casts,
    CASE 
        WHEN rm.rank IS NULL THEN 'Not Ranked'
        ELSE 'Ranked'
    END AS rank_status
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedMovies rm ON mh.movie_id = rm.movie_id
WHERE 
    mh.depth = 0  -- Only top-level movies
ORDER BY 
    mh.production_year DESC, mh.depth;
This query combines CTEs for hierarchical exploration of linked movies, computes rankings based on cast and keyword counts, and handles various NULL situations through string expressions for a clear output. The complexity lies in recursive joins, window functions, outer joins, and conditional expressions.
