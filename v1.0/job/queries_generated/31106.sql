WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL AND mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
),
CastRoleCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        MAX(rt.role) AS main_role
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    COALESCE(cr.cast_count, 0) AS cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN mh.depth > 1 THEN 'Linked Movie'
        ELSE 'Standalone Movie'
    END AS movie_type
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastRoleCounts cr ON mh.movie_id = cr.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC,
    mh.title ASC;

This SQL query utilizes several advanced constructs including a recursive CTE `MovieHierarchy` to generate a tree structure of movies, a CTE `CastRoleCounts` to get the count of unique cast members and their main roles, and another CTE `MovieKeywords` to aggregate keywords associated with each movie. The final SELECT statement combines these results, applying some formatting logic to classify the movies based on their depth and filtering for production years after 2000. The result is sorted by production year and title for easy readability.
