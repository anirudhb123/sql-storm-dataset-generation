WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        CAST(m.title AS VARCHAR(MAX)) AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || a.title AS VARCHAR(MAX)) AS path
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(CASE 
            WHEN ci.role_id IS NOT NULL THEN 1 
            ELSE 0 
        END) AS role_participation,
    STRING_AGG(DISTINCT cn.name, ', ') AS cast_names,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Year Not Available'
        ELSE CAST(mh.production_year AS VARCHAR(4))
    END AS display_year
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id AND cc.movie_id = ci.movie_id
LEFT JOIN 
    aka_name cn ON ci.person_id = cn.person_id
WHERE 
    mh.level <= 1
GROUP BY 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path
ORDER BY 
    mh.production_year DESC, 
    mh.title ASC;

This query generates a recursive Common Table Expression (CTE) called `MovieHierarchy`, which creates a hierarchy of movies linked to other movies based on certain criteria. The results are filtered for movies produced in or after the year 2000. The main query retrieves movie details along with count of distinct cast members and their names for movies at level 0 and 1 in the hierarchy. It includes aggregate functions to derive additional insights and handles NULL values gracefully to enhance the display of year information.
