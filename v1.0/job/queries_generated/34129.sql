WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    movie.title AS main_movie,
    movie.production_year,
    COUNT(DISTINCT cast.person_id) AS total_cast,
    string_agg(DISTINCT aka.name, ', ') AS actors,
    AVG(COALESCE(mvi.info::integer, 0)) AS avg_budget,
    MAX(mvi2.info) AS highest_revenue,
    COALESCE(comp.name, 'Independent') AS production_company
FROM 
    movie_hierarchy movie
LEFT JOIN 
    complete_cast cc ON movie.movie_id = cc.movie_id
LEFT JOIN 
    cast_info cast ON cc.subject_id = cast.person_id
LEFT JOIN 
    aka_name aka ON cast.person_id = aka.person_id
LEFT JOIN 
    movie_info mvi ON movie.movie_id = mvi.movie_id AND mvi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
LEFT JOIN 
    movie_info mvi2 ON movie.movie_id = mvi2.movie_id AND mvi2.info_type_id = (SELECT id FROM info_type WHERE info = 'revenue')
LEFT JOIN 
    movie_companies mc ON movie.movie_id = mc.movie_id
LEFT JOIN 
    company_name comp ON mc.company_id = comp.id
WHERE 
    movie.production_year >= 2000
    AND (mvi.info IS NOT NULL OR mvi2.info IS NOT NULL)
GROUP BY 
    movie.title, movie.production_year, comp.name
ORDER BY 
    movie.production_year DESC,
    total_cast DESC;
