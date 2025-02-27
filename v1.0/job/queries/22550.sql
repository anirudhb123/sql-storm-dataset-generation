
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    COALESCE(c.name, 'Unknown') AS cast_name,
    COALESCE(string_agg(DISTINCT kw.keyword, ', ' ORDER BY kw.keyword), 'No Keywords') AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN (mi.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice')) THEN CAST(mi.info AS DECIMAL) ELSE 0 END) AS total_box_office
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
LEFT JOIN 
    (SELECT DISTINCT name FROM char_name WHERE name IS NOT NULL AND LENGTH(name) > 0) AS c ON c.name = ak.name
WHERE 
    mh.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('Feature', 'Documentary'))
    AND (mh.production_year IS NOT NULL AND mh.production_year BETWEEN 2000 AND 2023)
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth, c.name
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    total_box_office DESC, mh.depth ASC NULLS LAST;
