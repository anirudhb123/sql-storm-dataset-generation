WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mp.name AS company_name, 
        1 AS level
    FROM 
        aka_title AS mt
    JOIN 
        movie_companies AS mc ON mc.movie_id = mt.id
    JOIN 
        company_name AS mp ON mp.id = mc.company_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.movie_title,
        mp.name AS company_name,
        mh.level + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS mt ON mt.id = ml.linked_movie_id
    JOIN 
        movie_companies AS mc ON mc.movie_id = mt.id
    JOIN 
        company_name AS mp ON mp.id = mc.company_id
    WHERE 
        mh.level < 5
), RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.company_name,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.level DESC) AS rank_level
    FROM 
        MovieHierarchy AS mh
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    COUNT(DISTINCT mc.movie_id) AS num_of_companies,
    STRING_AGG(DISTINCT rm.company_name, ', ') AS companies
FROM 
    RankedMovies AS rm 
LEFT JOIN 
    movie_companies AS mc ON mc.movie_id = rm.movie_id
GROUP BY 
    rm.movie_id, rm.movie_title
HAVING 
    COUNT(DISTINCT mc.movie_id) > 1
ORDER BY 
    num_of_companies DESC, rm.movie_title ASC;
