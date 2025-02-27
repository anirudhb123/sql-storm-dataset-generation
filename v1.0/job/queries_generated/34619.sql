WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT mc.company_id) AS number_of_companies,
    STRING_AGG(DISTINCT ckt.kind, ', ') AS unique_company_types,
    AVG(CASE WHEN pi.info_type_id = 1 THEN p_info.info::float ELSE NULL END) AS average_rating,
    ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mh.depth DESC) AS movie_depth_ranking
FROM 
    cast_info ci 
JOIN 
    aka_name ak ON ci.person_id = ak.person_id 
JOIN 
    aka_title mt ON ci.movie_id = mt.id 
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id 
LEFT JOIN 
    company_type ckt ON mc.company_type_id = ckt.id 
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = 1 
JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    mt.production_year >= 2000 
    AND mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    ak.name, mt.id, mt.title, mt.production_year 
ORDER BY 
    number_of_companies DESC,
    movie_depth_ranking;

This SQL query performs the following operations:
1. The **CTE (Common Table Expression)** called `MovieHierarchy` recursively finds all movies linked to those released after 2000, creating a hierarchy based on the links between movies.
2. The main query joins the cast information with names and titles, and also retrieves information about the companies associated with each movie.
3. It uses **aggregate functions** to count distinct companies, retrieve unique company types, and calculate average ratings from the person information.
4. A **window function** (ROW_NUMBER) is employed to assign ranks based on the movie depth in the hierarchy.
5. The **WHERE** clause incorporates various filters to ensure only relevant movies are processed.
6. The results are grouped and ordered for optimal insights into connections within the movie industry over the last two decades.
