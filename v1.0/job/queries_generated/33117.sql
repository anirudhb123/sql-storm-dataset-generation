WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title AS m
    WHERE 
        m.kind_id = 1  -- assuming kind_id = 1 is for 'movie'
    
    UNION ALL
    
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1 AS depth,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title AS m
    JOIN 
        movie_link AS ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    mh.depth AS Movie_Depth,
    COALESCE(cast.name, 'Unknown') AS Cast_Name,
    c.name AS Company_Name,
    COUNT(DISTINCT mk.keyword) AS Keyword_Count,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.depth) AS Row_Num
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    complete_cast AS cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name AS cast ON ci.person_id = cast.person_id
LEFT JOIN 
    movie_companies AS mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name AS c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword AS mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
    AND (c.country_code IS NULL OR c.country_code != 'US')
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth, cast.name, c.name
ORDER BY 
    mh.production_year DESC, Movie_Title
LIMIT 100;

This SQL query utilizes various constructs:
- A recursive CTE (`MovieHierarchy`) to create hierarchical data about movies, their links, and depth in the hierarchy.
- LEFT JOINs to connect `complete_cast`, `cast_info`, `aka_name`, `movie_companies`, and `company_name` to gather necessary information about movies, cast, and production companies.
- A WHERE clause with complicated NULL logic using `COALESCE` and filtering on production years and company country codes.
- Utilization of `COUNT` to derive the count of unique keywords associated with each movie.
- A `ROW_NUMBER()` window function to assign a sequential number within each movie group based on depth.
- Final ordering by production year and movie title, limiting the result to the first 100 entries for performance benchmarking.
