WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ARRAY_AGG(DISTINCT ak.name) AS cast_names,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(mh.production_year AS TEXT)
    END AS production_year_info,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS row_num
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ak.name) > 5 OR COUNT(DISTINCT mk.keyword) > 3
ORDER BY 
    mh.production_year DESC, 
    mh.title;
