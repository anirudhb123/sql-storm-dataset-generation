WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY[mt.title] AS title_path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.title_path || at.title
    FROM 
        movie_link ml
        JOIN aka_title at ON ml.linked_movie_id = at.id
        JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No Cast') AS cast_names,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS row_num,
    CASE
        WHEN mh.production_year IS NULL THEN 'Unknown Year'
        ELSE mh.production_year::TEXT
    END AS year_display,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM movie_info mi
            WHERE mi.movie_id = mh.movie_id AND mi.info LIKE '%Award%'
        ) THEN TRUE
        ELSE FALSE
    END AS award_winner
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ak.name) > 1 AND mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC, mh.title;
