WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    COUNT(DISTINCT mc.company_id) FILTER (WHERE ct.kind = 'Production') AS production_company_count,
    MAX(m.title) OVER (PARTITION BY mh.level) AS max_title_at_level,
    (SELECT AVG(DISTINCT mii.info)::NUMERIC FROM movie_info_idx mii WHERE mii.movie_id = mh.movie_id AND mii.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')) AS average_rating
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    (mh.production_year IS NOT NULL AND mh.production_year > 2010) 
    AND (ak.name IS NOT NULL OR ak.name <> '')
    AND (mc.note IS NULL OR mc.note NOT LIKE '%Unknown%')
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, cast_count DESC;
