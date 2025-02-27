WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mc.company_id,
        c.name AS company_name,
        1 AS level
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        mc.note IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        mt.title,
        mt.production_year,
        mc.company_id,
        c.name AS company_name,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        aka_title mt ON mh.movie_id = mt.id
    WHERE 
        mh.level < 5
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    STRING_AGG(DISTINCT mh.company_name, ', ') AS companies,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank,
    COUNT(*) OVER (PARTITION BY mh.production_year) AS total_companies,
    (SELECT COUNT(DISTINCT c.person_id)
     FROM cast_info c
     WHERE c.movie_id = mh.movie_id) AS total_cast_members,
    COALESCE(MAX(cast.person_role_id), 0) AS max_role_id 
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info cast ON mh.movie_id = cast.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, rank
LIMIT 100;

This SQL query constructs a recursive common table expression (CTE) to build a hierarchy of movies and their associated companies, while also performing complex aggregations and calculations such as counting total cast members and determining the maximum role ID for each movie. The final result is filtered to show the top 100 movies ordered by production year and rank, with comprehensive string aggregations for companies involved in each movie.
