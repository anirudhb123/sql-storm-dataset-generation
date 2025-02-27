WITH RECURSIVE MovieHierarchy AS (
    -- Starting point: get top-level movies
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
        
    UNION ALL
    
    -- Recursive query: get episodes for each movie
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        aka_title a
    JOIN 
        MovieHierarchy mh ON a.episode_of_id = mh.movie_id
),
MovieWithKeywords AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        k.keyword
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
MovieInfo AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        COALESCE(mi.info, 'No info available') AS info,
        ROW_NUMBER() OVER (PARTITION BY mwk.movie_id ORDER BY mi.info_type_id) AS info_rank
    FROM 
        MovieWithKeywords mwk
    LEFT JOIN 
        movie_info mi ON mwk.movie_id = mi.movie_id
)
SELECT 
    m.title,
    m.production_year,
    STRING_AGG(m.keyword, ', ') AS keywords,
    STRING_AGG(mi.info, '; ') AS movie_info
FROM 
    MovieWithKeywords m
LEFT JOIN 
    MovieInfo mi ON m.movie_id = mi.movie_id
WHERE 
    m.production_year >= 2000
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(m.keyword) > 2 
    OR COUNT(mi.info) = 0
ORDER BY 
    m.production_year DESC, m.title;

This SQL query performs multiple tasks:
1. It defines a recursive CTE (`MovieHierarchy`) to obtain both movies and their episode-level relationships.
2. It constructs another CTE (`MovieWithKeywords`) to gather movie titles along with their keywords.
3. A third CTE (`MovieInfo`) aggregates information types related to those movies.
4. Finally, it groups the results based on production year and title, applying filters to only include movies released after 2000 with more than two keywords or lacking info, concatenating keywords and additional movie info using string aggregation functions.
5. The ordering is performed primarily by production year in descending order, allowing recent movies to appear first.
