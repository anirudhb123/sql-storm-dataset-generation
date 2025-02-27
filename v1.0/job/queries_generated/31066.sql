WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title a ON a.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    cs.cast_names,
    COALESCE(ks.keywords, 'No keywords') AS keywords,
    mh.depth
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    keyword_summary ks ON mh.movie_id = ks.movie_id
WHERE 
    mh.production_year > 2000
ORDER BY 
    mh.production_year DESC, 
    mh.depth ASC, 
    COALESCE(cs.total_cast, 0) DESC;

This SQL query accomplishes the following:
- It uses a **recursive CTE** (`movie_hierarchy`) to build a hierarchy of movies and their linked counterparts, allowing for an interesting exploration of movie relationships.
- It calculates a summary of cast information (`cast_summary`) by aggregating total cast and names for each movie.
- It collects associated keywords (`keyword_summary`) for each movie.
- The main query combines the recursive hierarchy with cast and keyword information, filtering for movies produced after the year 2000 and ordering results based on production year, depth of hierarchy, and total cast count. 
- **NULL logic** is applied effectively using `COALESCE` to handle cases where no casting or keywords are found, providing a coherent response even when data is missing.
