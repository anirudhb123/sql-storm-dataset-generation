WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000  -- Starting point: Movies made after 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.production_year > 2000  -- Continuing search for linked movies

),
FilteredCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ci.nr_order < 5  -- Consider only main cast members
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        fc.total_cast,
        fc.cast_names,
        COALESCE(ki.keyword, 'No Keywords') AS keywords
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        FilteredCast fc ON mh.movie_id = fc.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    COUNT(mdk.keyword) AS keyword_count,
    COUNT(*) OVER (PARTITION BY md.production_year) AS movies_per_year
FROM 
    MovieDetails md
GROUP BY 
    md.title, md.production_year, md.total_cast, md.cast_names
HAVING 
    COUNT(mdk.keyword) > 1  -- Only movies with more than one keyword
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC;

-- Additional performance benchmarking
EXPLAIN ANALYZE
SELECT 
    AVG(total_cast) AS avg_cast_size,
    MAX(total_cast) AS max_cast_size,
    MIN(total_cast) AS min_cast_size
FROM 
    FilteredCast;
