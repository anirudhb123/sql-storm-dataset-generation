WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Considering movies from the year 2000 onward

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml 
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COALESCE(c.name, 'Unknown') AS company_name,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ' ORDER BY ak.name) AS actor_names,
    SUM(
        CASE 
            WHEN ni.info IS NOT NULL THEN 1 
            ELSE 0 
        END
    ) AS info_count,
    RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
FROM 
    MovieHierarchy m
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = m.movie_id
LEFT JOIN 
    info_type ni ON ni.id = mi.info_type_id
WHERE 
    m.level <= 2  -- Limit hierarchy to only two levels
GROUP BY 
    m.id, m.title, m.production_year, c.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    m.production_year DESC, rank_by_cast
LIMIT 20;  -- Limiting results for performance

This query constructs a recursive CTE to explore a hierarchy of linked movies, and then aggregates various pieces of information, including the names of actors, the count of cast members, and the linked company names. It incorporates outer joins, string aggregation, window functions, and applies filtering, grouping, and ordering to ensure performance and relevancy of results.
