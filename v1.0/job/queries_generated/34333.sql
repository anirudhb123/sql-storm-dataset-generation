WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year >= 2000
)

SELECT 
    mv.title AS MovieTitle,
    mv.production_year AS ProductionYear,
    STRING_AGG(DISTINCT ak.name, ', ') AS ActorNames,
    COUNT(DISTINCT kc.keyword) AS KeywordCount,
    AVG(COALESCE(mk.rating, 0)) AS AverageRating,
    COUNT(DISTINCT mc.company_id) AS CompanyCount,
    FIRST_VALUE(mv.production_year) OVER (PARTITION BY mv.production_year ORDER BY mv.production_year DESC) AS LatestYearInCategory
FROM 
    MovieHierarchy mv
LEFT JOIN 
    complete_cast cc ON mv.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mv.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON mv.movie_id = mc.movie_id
GROUP BY 
    mv.movie_id, mv.title, mv.production_year
HAVING 
    COUNT(DISTINCT ak.name) > 1
ORDER BY 
    AverageRating DESC NULLS LAST;
