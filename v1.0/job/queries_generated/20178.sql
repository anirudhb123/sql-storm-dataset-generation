WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mt.kind_id,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        at.title, 
        at.production_year, 
        at.kind_id,
        mh.movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ARRAY_AGG(DISTINCT co.name) AS companies_involved,
    COUNT(DISTINCT c.person_id) AS total_cast_members,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors_names,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY a.role_id) AS median_role_id
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT ID FROM info_type WHERE info = 'Summary')
WHERE 
    mh.production_year IS NOT NULL AND
    (mh.production_year < 2022 OR mi.info IS NOT NULL)
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ak.name) > 3 OR COUNT(DISTINCT co.id) > 2
ORDER BY 
    mh.production_year DESC,
    total_cast_members DESC;
