WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    kt.kind AS Movie_Kind,
    COUNT(DISTINCT ca.person_id) AS Cast_Count,
    AVG(pi.info_type_id) AS Avg_Info_Type,
    STRING_AGG(DISTINCT co.name, ', ') AS Companies_Involved
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    company_name co ON co.id IN (
        SELECT 
            mc.company_id
        FROM 
            movie_companies mc
        WHERE 
            mc.movie_id = mh.movie_id
    )
LEFT JOIN 
    kind_type kt ON mh.kind_id = kt.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    person_info pi ON ca.person_id = pi.person_id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, kt.kind
HAVING 
    COUNT(DISTINCT ca.person_id) > 1
ORDER BY 
    mh.production_year DESC, Movie_Title;
