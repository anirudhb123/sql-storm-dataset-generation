WITH RecursiveMovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        1 AS level
    FROM 
        aka_title AS title
    INNER JOIN 
        movie_link AS ml ON title.id = ml.movie_id
    WHERE 
        ml.linked_movie_id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        level + 1
    FROM 
        RecursiveMovieHierarchy AS rmh
    INNER JOIN 
        movie_link AS ml ON rmh.movie_id = ml.movie_id
    INNER JOIN 
        aka_title AS title ON ml.linked_movie_id = title.id
)

SELECT 
    mk.keyword,
    COUNT(DISTINCT mi.movie_id) AS movie_count,
    MIN(title.production_year) AS earliest_production_year,
    MAX(title.production_year) AS latest_production_year,
    STRING_AGG(DISTINCT CONCAT_WS(' | ', title.title, CASE 
        WHEN pc.name IS NOT NULL THEN pc.name ELSE 'Unknown' END
    )) AS title_and_company,
    ROW_NUMBER() OVER (PARTITION BY mk.keyword ORDER BY COUNT(DISTINCT mi.movie_id) DESC) AS row_num
FROM 
    movie_keyword AS mk
LEFT JOIN 
    movie_info AS mi ON mk.movie_id = mi.movie_id 
LEFT JOIN 
    RecursiveMovieHierarchy AS title ON mi.movie_id = title.movie_id
LEFT JOIN 
    movie_companies AS mc ON title.movie_id = mc.movie_id
LEFT JOIN 
    company_name AS pc ON mc.company_id = pc.id
WHERE 
    mk.keyword IS NOT NULL
    AND (title.production_year IS NULL OR title.production_year >= 2000)
GROUP BY 
    mk.id, mk.keyword
HAVING 
    COUNT(DISTINCT mi.movie_id) > 5
    AND COALESCE(MIN(title.production_year), 0) > 2010
ORDER BY 
    movie_count DESC, earliest_production_year ASC
LIMIT 50;


