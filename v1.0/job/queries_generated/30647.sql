WITH RECURSIVE MovieHierarchy AS (
    -- Recursive CTE to build a hierarchy of movies for series and episodes
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.episode_of_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- Start with top-level movies
    
    UNION ALL
    
    SELECT 
        ep.id AS movie_id,
        ep.title,
        ep.production_year,
        ep.episode_of_id,
        mh.level + 1
    FROM 
        aka_title ep
    JOIN 
        MovieHierarchy mh ON ep.episode_of_id = mh.movie_id
), 

MovieInfo AS (
    -- Aggregate movie info related to keywords and genres
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT kt.kind, ', ') AS kinds
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        kind_type kt ON m.kind_id = kt.id
    GROUP BY 
        m.id, m.title
),

CastDetails AS (
    -- Fetch details of cast members, including roles and names
    SELECT 
        ci.movie_id,
        p.name AS person_name,
        ci.nr_order,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS cast_order
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mi.keywords,
    mi.kinds,
    cd.person_name,
    cd.role,
    cd.cast_order
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_id
WHERE 
    (mh.level = 0 OR cd.role IS NOT NULL)  -- Include top-level movies and those with cast
ORDER BY 
    mh.production_year DESC, mh.title, cd.cast_order;

-- Benchmarking performance across different constructs like CTE, joins, aggregation
-- Optimized for readability while demonstrating complex relationships in data.
