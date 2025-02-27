WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mci.company_id,
        cn.name AS company_name,
        1 AS level
    FROM 
        aka_title mt
    JOIN 
        movie_companies mci ON mt.id = mci.movie_id
    LEFT JOIN 
        company_name cn ON mci.company_id = cn.id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mci.company_id,
        cn.name AS company_name,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_companies mci ON mh.movie_id = mci.movie_id
    LEFT JOIN 
        company_name cn ON mci.company_id = cn.id
    WHERE 
        mh.level < 3  -- Limit levels to prevent infinite recursion
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.company_name,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors_names,
    CASE 
        WHEN COUNT(DISTINCT ci.person_id) > 5 THEN 'Large Cast'
        WHEN COUNT(DISTINCT ci.person_id) BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    mh.company_name IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.company_name
ORDER BY 
    mh.production_year DESC, cast_count DESC;
