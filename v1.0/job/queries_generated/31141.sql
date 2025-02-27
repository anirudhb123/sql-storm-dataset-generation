WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all movies with their basic details
    SELECT 
        mt.id AS movie_id,
        mt.title, 
        mt.production_year, 
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Consider movies from the year 2000 onwards

    UNION ALL

    -- Recursive case: Join to find related movies (using movie_link)
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title, 
        mt.production_year, 
        mt.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    M.id AS movie_id,
    M.title,
    M.production_year,
    C.kind AS company_type,
    COUNT(DISTINCT CI.person_id) AS total_actors,
    CASE 
        WHEN C.id IS NOT NULL THEN 'Has Company'
        ELSE 'No Company'
    END AS company_presence,
    STRING_AGG(DISTINCT AK.name, ', ') AS actor_names,
    AVG(PI.info::numeric) AS average_rating
FROM 
    MovieHierarchy M
LEFT JOIN 
    movie_companies MC ON M.movie_id = MC.movie_id
LEFT JOIN 
    company_name C ON MC.company_id = C.id
LEFT JOIN 
    complete_cast CC ON M.movie_id = CC.movie_id
LEFT JOIN 
    cast_info CI ON CC.subject_id = CI.person_id
LEFT JOIN 
    aka_name AK ON CI.person_id = AK.person_id
LEFT JOIN 
    movie_info MI ON M.movie_id = MI.movie_id AND MI.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    person_info PI ON CI.person_id = PI.person_id
GROUP BY 
    M.id, M.title, M.production_year, C.kind
HAVING 
    COUNT(DISTINCT CI.person_id) > 0  -- Only movies that have at least one actor
ORDER BY 
    average_rating DESC NULLS LAST;  -- Order by average rating, putting NULLs last

