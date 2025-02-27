
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_id
    FROM
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mc.movie_id AS parent_id
    FROM
        complete_cast mc
        JOIN aka_title mt ON mc.movie_id = mt.id
    WHERE 
        mc.subject_id IS NOT NULL
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ARRAY_AGG(DISTINCT ak.name) AS actors,
    ARRAY_AGG(DISTINCT cn.name) AS companies
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC;
