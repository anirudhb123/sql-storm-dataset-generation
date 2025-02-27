WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        ARRAY[mt.title] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (1, 2) -- 1: movie, 2: tv show
          
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        mh.path || at.title
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5  -- Limit recursion to a depth of 5 levels
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    COALESCE(AVG(ci.nr_order), 0) AS avg_order,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT an.name, ', ') AS cast_names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id 
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.path
ORDER BY 
    mh.production_year DESC, 
    mh.level, 
    mh.title;

-- Additional considerations:
-- 1. The recursive CTE fetches movies and their linked counterparts up to 5 levels deep from the "aka_title" table.
-- 2. Each movie is grouped to calculate the average cast ordering and total cast count per movie.
-- 3. The cast names are aggregated into a single string for easier readability.
-- 4. The final output is ordered by the production year, level, and title for structured presentation.
