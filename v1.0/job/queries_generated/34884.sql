WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all movies and their first-level cast members
    SELECT 
        m.id AS movie_id,
        m.title,
        c.person_id,
        1 AS level
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    
    UNION ALL

    -- Recursive case: Select cast members of cast members (for demonstration - not actual casting)
    SELECT 
        mh.movie_id,
        mh.title,
        c.person_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        cast_info c ON mh.movie_id = c.movie_id
    WHERE 
        mh.level < 3  -- Limit the depth of recursion
),

AggregatedCast AS (
    -- Aggregate to count the number of cast members by movie
    SELECT 
        movie_id,
        title,
        COUNT(person_id) AS cast_count
    FROM 
        MovieHierarchy
    GROUP BY 
        movie_id, title
),

MovieDetails AS (
    -- Join with movie_info to get additional details
    SELECT 
        a.title,
        a.production_year,
        ac.cast_count,
        COALESCE(mk.keyword, 'No Keyword') AS keyword
    FROM 
        aggregatedCast ac
    JOIN 
        aka_title a ON ac.movie_id = a.id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Runtime' LIMIT 1)
)

SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.keyword,
    ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.cast_count DESC) AS rank,
    CASE 
        WHEN md.cast_count > 10 THEN 'Well Cast'
        WHEN md.cast_count IS NULL THEN 'No Cast Info'
        ELSE 'Under Cast'
    END AS cast_status
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000 -- Filter for movies from the year 2000 onwards
ORDER BY 
    md.production_year DESC;

This query builds a recursive Common Table Expression (CTE) to establish a movie hierarchy, counting cast members while providing additional movie details. It utilizes outer joins and window functions for ranking and conditional status labeling. The logic also includes NULL checks and aggregates data intelligently for insightful performance benchmarking results.
